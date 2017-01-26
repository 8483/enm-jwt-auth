module Login exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Encode as JE
import Json.Decode as JD
import Navigation

-- model

type alias Model =
    { username : String
    , password : String
    , error : Maybe String
    }

initModel : Model
initModel =
    { username = ""
    , password = ""
    , error = Nothing
    }

init : ( Model, Cmd Msg )
init =
    ( initModel, Cmd.none )

-- update

type Msg
    = UsernameInput String
    | PasswordInput String
    | Submit
    | Error String
    | LoginResponse ( Result Http.Error String )

url : String
url =
    "http://localhost:3000/api/authenticate"

update : Msg -> Model -> ( Model, Cmd Msg, Maybe String )
update msg model =
    case msg of
        UsernameInput username ->
            ( { model | username = username }, Cmd.none, Nothing )

        PasswordInput password ->
            ( { model | password = password }, Cmd.none, Nothing )

        Submit ->
            let
                body =
                    JE.object
                        [ ( "username", JE.string model.username )
                        , ( "password", JE.string model.password )
                        ]
                        |> JE.encode 4
                        |> Http.stringBody "application/json"

                decoder =
                    JD.field "token" JD.string

                request =
                    Http.post url body decoder

                cmd =
                    Http.send LoginResponse request
            in
                ( model, cmd, Nothing )

        Error error ->
            ( { model | error = Just error }, Cmd.none, Nothing )

        LoginResponse (Ok token) ->
            ( initModel, Navigation.newUrl "#/", Just token )

        LoginResponse (Err err) ->
            let
                errMsg =
                    case err of
                        Http.BadStatus resp ->
                            case resp.status.code of
                                401 ->
                                    resp.body
                                _ ->
                                    resp.status.message
                        _ ->
                            "Login Error!"
            in
                ( { model | error = Just errMsg }, Cmd.none, Nothing )

-- view

view : Model -> Html Msg
view model =
    div [ class "row height-80col" ]
        [ loginForm model
        ]

loginForm : Model -> Html Msg
loginForm model =
    div [ class "row" ]
        [ Html.form
            [ class "col-sm-2 col-sm-offset-5", onSubmit Submit ]
            [ br [][]
            , div []
                [ input
                    [ type_ "text"
                    , class "form-control"
                    , placeholder "Username"
                    , value model.username
                    , onInput UsernameInput
                    ]
                    []
                ]
            , br [][]
            , div []
                [ input
                    [ type_ "password"
                    , class "form-control"
                    , placeholder "Password"
                    , value model.password
                    , onInput PasswordInput
                    ]
                    []
                ]
            , br [][]
            , div []
                [ button
                    [ type_ "submit"
                    , class "btn btn-primary" ]
                    [ text "Login" ]
                ]
            , br [][]
            , errorPanel model.error
            ]
        ]

errorPanel : Maybe String -> Html a
errorPanel error =
    case error of
        Nothing ->
            text ""

        Just msg ->
            div [ class "alert alert-danger" ]
                [ text msg ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
