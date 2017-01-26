port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)

import Html.Events exposing (..)
import Navigation
import Login
import Dashboard
import ChildModule

-- model

type alias Model =
    { page : Page
    , childModule : ChildModule.Model
    , dashboard : Dashboard.Model
    , login : Login.Model
    , token : Maybe String
    , loggedIn : Bool
    }

type Page
    = NotFound
    | ChildModulePage
    | DashboardPage
    | LoginPage

authPages : List Page
authPages =
    [ ChildModulePage ]

init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init flags location =
    let
        page =
            hashToPage location.hash

        loggedIn =
            flags.token /= Nothing

        ( updatedPage, cmd ) =
            authRedirect page loggedIn

        ( childModuleInitModel, childModuleCmd ) =
            ChildModule.init

        ( dashboardInitModel, dashboardCmd ) =
            Dashboard.init

        ( loginInitModel, loginCmd ) =
            Login.init

        initModel =
            { page = updatedPage
            , childModule = childModuleInitModel
            , dashboard = dashboardInitModel
            , login = loginInitModel
            , token = flags.token
            , loggedIn = loggedIn
            }

        cmds =
            Cmd.batch
                [ Cmd.map ChildModuleMsg childModuleCmd
                , Cmd.map DashboardMsg dashboardCmd
                , Cmd.map LoginMsg loginCmd
                , cmd ]
    in
        ( initModel, cmds )

-- update

type Msg
    = Navigate Page
    | ChangePage Page
    | ChildModuleMsg ChildModule.Msg
    | DashboardMsg Dashboard.Msg
    | LoginMsg Login.Msg
    | Logout

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Navigate page ->
            ( { model | page = page }, Navigation.newUrl ( pageToHash page ) )

        ChangePage page ->
            let
            -- This (updatedPage, cmd) is used because of the update type annotation of (Model, Cmd Msg). We can't simply use "updatedPage =" because of the annotation. This is called tuple destructuring (pattern matching) @ 06:50 "Setting Up Navigation"
                ( updatedPage, cmd ) =
                    authRedirect page model.loggedIn
            in
                ( { model | page = updatedPage }, cmd )
                -- It matches this part, i.e. updatedPage = authRedirect page model.loggedIn.

        ChildModuleMsg msg ->
            let
                ( childModuleModel, cmd ) =
                    ChildModule.update msg model.childModule
            in
                ( { model | childModule = childModuleModel } -- childModuleModel = ChildModule.update msg model.childModule
                , Cmd.map ChildModuleMsg cmd )

        DashboardMsg msg ->
            let
                ( dashboardModel, cmd ) =
                    Dashboard.update msg model.dashboard
            in
                ( { model | dashboard = dashboardModel }
                , Cmd.map DashboardMsg cmd )

        LoginMsg msg ->
            let
                ( loginModel, cmd, token ) =
                    Login.update msg model.login

                loggedIn =
                    token /= Nothing

                saveTokenCmd =
                    case token of
                        Just jwt ->
                            saveToken jwt
                        Nothing ->
                            Cmd.none
            in
                ( { model
                    | login = loginModel
                    , token = token
                    , loggedIn = loggedIn
                    }
                , Cmd.batch
                    [ Cmd.map LoginMsg cmd
                    , saveTokenCmd
                    ]
                )

        Logout ->
            ( { model
                | loggedIn = False
                , token = Nothing
                }
            , Cmd.batch
                [ deleteToken ()
                , Navigation.modifyUrl <| pageToHash LoginPage
                ]
            )

authForPage : Page -> Bool -> Bool
authForPage page loggedIn =
    loggedIn || not (List.member page authPages)

authRedirect : Page -> Bool -> ( Page, Cmd Msg )
authRedirect page loggedIn =
    if authForPage page loggedIn then
        ( page, Cmd.none )
    else
        ( LoginPage, Navigation.modifyUrl <| pageToHash LoginPage )

-- view

view : Model -> Html Msg
view model =
    let
        page =

            case model.page of
                ChildModulePage ->
                    Html.map ChildModuleMsg
                        ( ChildModule.view model.childModule )

                DashboardPage ->
                    Html.map DashboardMsg
                        ( Dashboard.view model.dashboard )

                LoginPage ->
                    Html.map LoginMsg
                        ( Login.view model.login )

                NotFound ->
                    div [ class "main" ]
                        [ h1 []
                            [ text "Page Not Found!" ]
                        ]
    in
        div [ class "container-fluid full-height" ]
            [ pageHeader model
            , page
            ]

authHeaderView : Model -> Html Msg
authHeaderView model =
    if model.loggedIn then
        div [ class "col-md-1 cursor", onClick Logout ]
            [ text "Logout" ]
    else
        div [ class "col-md-1 cursor", onClick (Navigate LoginPage) ]
            [ text "Login" ]



childModuleLinkView : Model -> Html Msg
childModuleLinkView { loggedIn } =
    if loggedIn then
        div [ onClick (Navigate ChildModulePage) ] [ text "ChildModule" ]
    else
        div [] []

pageHeader : Model -> Html Msg
pageHeader model =
    nav [ class "row navbar navbar-default"]
        [ div [ class "container-fluid"]
            [ div [ class "navbar-header"]
                [ button [ type_ "button", class "navbar-toggle collapsed", attribute "data-toggle" "collapse", attribute "data-target" "#menu", attribute "aria-expanded" "false"]
                    [ span [ class "sr-only" ] [ text "Toggle navigation" ]
                    , span [ class "icon-bar" ] []
                    , span [ class "icon-bar" ] []
                    , span [ class "icon-bar" ] []
                    ]
                ]
            , div [ class "row navbar-collapse collapse", id "menu" ]
                [ div [ class "col-md-1 cursor", onClick (Navigate DashboardPage) ]
                    [ text "LOGO" ]
                , div [ class "col-md-10 bold"]
                    [ ul []
                        [ li [] [ childModuleLinkView model ]
                        ]
                    ]
                , authHeaderView model
                ]
            ]
        ]

-- subscriptions

subscriptions : Model -> Sub Msg
subscriptions model =
    let
        childModuleSub =
            ChildModule.subscriptions model.childModule

        dashboardSub =
            Dashboard.subscriptions model.dashboard

        loginSub =
            Login.subscriptions model.login
    in
        Sub.batch
            [ Sub.map ChildModuleMsg childModuleSub
            , Sub.map DashboardMsg dashboardSub
            , Sub.map LoginMsg loginSub ]

hashToPage : String -> Page
hashToPage hash =
    case hash of
        "#/" ->
            DashboardPage
        "" ->
            DashboardPage
        "#/childmodule" ->
            ChildModulePage
        "#/login" ->
            LoginPage
        _ ->
            NotFound

pageToHash : Page -> String
pageToHash page =
    case page of
        DashboardPage ->
            "#/"
        ChildModulePage ->
            "#/childmodule"
        LoginPage ->
            "#/login"
        NotFound ->
            "#notfound"


locationToMsg : Navigation.Location -> Msg
locationToMsg location =
    location.hash
        |> hashToPage
        |> ChangePage

type alias Flags =
    { token : Maybe String
    }

main : Program Flags Model Msg
main =
    Navigation.programWithFlags locationToMsg
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }

-- ports

port saveToken : String -> Cmd msg

port deleteToken : () -> Cmd msg
