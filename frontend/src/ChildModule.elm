module ChildModule exposing (..)

import Html exposing (..)
-- import Html.Events exposing (..)
import Html.Attributes exposing (..)

-- model

type alias Model =
    { something : String
    }

initModel : Model
initModel =
    { something = "ChildModule"
    }

init : ( Model, Cmd Msg )
init =
    ( initModel, Cmd.none )

-- update

type Msg
    = DoNothing

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DoNothing ->
            ( model, Cmd.none )

-- view

view : Model -> Html Msg
view model =
    div [ class "row" ]
        [ div [ class "large" ]
            [ text model.something ]
        ]

-- subscriptions

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
