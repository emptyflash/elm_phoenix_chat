module Main exposing (..)

import Dict

import Html exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Html.Attributes exposing (value, type_, placeholder)

import Json.Encode as Encoder
import Json.Decode as Decoder exposing (Decoder, field)

import Phoenix.Socket as Socket exposing (Socket)
import Phoenix.Channel as Channel exposing (Channel)
import Phoenix.Push as Push

import Markdown

main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }

type alias Model =
    { socket: Socket Msg
    , newMessage : String
    , messages : List ChatMessage
    , user: String
    , joined: Bool
    }

type alias ChatMessage = 
    { user : String
    , body : String
    }

type Msg 
    = SendMessage
    | SetNewMessage String
    | SetUsername String
    | PhoenixMsg (Socket.Msg Msg)
    | ReceiveChatMessage Encoder.Value
    | JoinChannel
    | LeaveChannel
    | ShowJoinedMessage String
    | ShowLeftMessage String
    | NoOp

subscriptions : Model -> Sub Msg
subscriptions model =
    Socket.listen model.socket PhoenixMsg

websocketUrl : String
websocketUrl =
    "ws://b115756c.ngrok.io/socket/websocket"

initSocket : Socket Msg
initSocket =
    Socket.init websocketUrl
        |> Socket.withDebug
        |> Socket.on "new:msg" "room:lobby" ReceiveChatMessage

initModel : Model
initModel =
    { socket = initSocket
    , newMessage = ""
    , messages = []
    , user = ""
    , joined = False
    }

init : (Model, Cmd Msg)
init =
    (initModel, Cmd.none)

chatMessageDecoder : Decoder ChatMessage
chatMessageDecoder =
    Decoder.map2 ChatMessage
      (field "user" Decoder.string)
      (field "body" Decoder.string)

userParams : Encoder.Value
userParams =
    Encoder.object [ ("user_id", Encoder.string "123" ) ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        PhoenixMsg msg ->
            let
                ( socket, cmd ) = Socket.update msg model.socket
            in
                ( { model | socket = socket }, Cmd.map PhoenixMsg cmd )

        SendMessage ->
            let
                payload = 
                    Encoder.object
                        [ ( "user"
                          , Encoder.string model.user
                          )
                        , ( "body", Encoder.string model.newMessage )
                        ]
                push =
                    Push.init "new:msg" "room:lobby"
                        |> Push.withPayload payload

                ( newSocket, cmd ) =
                    Socket.push push model.socket
            in
                ( { model
                  | newMessage = ""
                  , socket = newSocket
                  }
                , Cmd.map PhoenixMsg cmd
                )

        SetNewMessage message ->
            ( { model | newMessage = message }, Cmd.none )

        SetUsername username ->
            ( { model | user = username }, Cmd.none )
        
        ReceiveChatMessage json ->
            case Decoder.decodeValue chatMessageDecoder json of
                Ok chatMessage ->
                    ( { model 
                      | messages = chatMessage :: model.messages 
                      }
                    , Cmd.none )
                Err error ->
                    ( model, Cmd.none )

        JoinChannel ->
            let
                channel =
                    Channel.init "room:lobby"
                        |> Channel.withPayload userParams
                        |> Channel.onJoin (always <| ShowJoinedMessage "room:lobby")
                        |> Channel.onClose (always <| ShowLeftMessage "room:lobby")
                ( newSocket, cmd ) =
                    Socket.join channel model.socket
            in
                ( { model | socket = newSocket, joined = True}
                , Cmd.map PhoenixMsg cmd
                )

        LeaveChannel ->
            let
                ( newSocket, cmd ) =
                    Socket.leave "room:lobby" model.socket
            in
                ( { model | socket = newSocket, joined = False}
                , Cmd.map PhoenixMsg cmd
                )

        ShowJoinedMessage channelName ->
            let 
                joinedMessage = 
                    ChatMessage "" <| "Joined " ++ channelName 
            in
                ( { model | messages = joinedMessage :: model.messages }
                , Cmd.none
                )

        ShowLeftMessage channelName ->
            let
                leftMessage =
                    ChatMessage "" <| "Left " ++ channelName
            in
                ( { model | messages = leftMessage :: model.messages }
                , Cmd.none
                )

        NoOp -> 
            ( model, Cmd.none )

view : Model -> Html Msg
view model =
    div []
        [ h3 [] [ text "Messages: " ]
        , ul [] <| List.reverse <| List.map viewMessage model.messages
        , if model.joined then
              newMessageForm model
          else
              joinForm model
        ]

joinForm : Model -> Html Msg
joinForm model =
    form [ onSubmit JoinChannel ]
        [ input 
            [ type_ "text"
            , value model.user
            , onInput SetUsername
            , placeholder "username"
            ]
            []
        , button [ type_ "submit" ] [ text "Join" ]
        ]

newMessageForm : Model -> Html Msg
newMessageForm model =
    form [ onSubmit SendMessage ]
        [ input 
            [ type_ "text"
            , value model.newMessage
            , onInput SetNewMessage
            ]
            []
        , button [ type_ "submit" ] [ text "Send" ]
        , button [ type_ "button", onClick LeaveChannel ] [ text "Leave" ]
        ]

viewMessage : ChatMessage -> Html Msg
viewMessage message =
    li [] [ span [] [ text message.user, text ": ", Markdown.toHtml [] message.body ] ]
