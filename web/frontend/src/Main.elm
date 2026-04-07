module Main exposing (main)

import Api
import Browser
import Html exposing (..)
import Html.Attributes as A exposing (class, id, style)
import Http
import Ports
import Random
import Set exposing (Set)
import Types exposing (..)
import View.Controls exposing (viewControls)
import View.Layout exposing (viewBadge, viewLegend, viewTopBar)
import View.Results exposing (viewResults)



-- MODEL


type alias Model =
    { instances : List InstanceInfo
    , source : Source
    , instanceName : String
    , genN : Int
    , genP : Float
    , genSeed : Int
    , algorithm : Algorithm
    , iterations : Int
    , temperature : Float
    , cooling : Float
    , graphData : Maybe GraphData
    , result : Maybe SolveResponse
    , manualSet : Set Int
    , manualStatus : Maybe (List VertexStatus)
    , solving : Bool
    , error : Maybe String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    let
        model =
            { instances = []
            , source = Random
            , instanceName = ""
            , genN = 40
            , genP = 0.15
            , genSeed = 42
            , algorithm = Greedy
            , iterations = 2000
            , temperature = 0
            , cooling = 0.995
            , graphData = Nothing
            , result = Nothing
            , manualSet = Set.empty
            , manualStatus = Nothing
            , solving = False
            , error = Nothing
            }
    in
    ( model
    , Cmd.batch
        [ Api.getInstances GotInstances
        , loadGraph model
        ]
    )



-- MSG


type Msg
    = GotInstances (Result Http.Error (List InstanceInfo))
    | SetSource Source
    | SetInstanceName String
    | SetGenN String
    | SetGenP String
    | SetGenSeed String
    | SetAlgorithm Algorithm
    | SetIterations String
    | SetTemperature String
    | SetCooling String
    | GotGraphData (Result Http.Error GraphData)
    | GotInstanceGraphData (Result Http.Error SolveResponse)
    | GotSolveResult (Result Http.Error SolveResponse)
    | GotValidateResult (Result Http.Error ValidateResponse)
    | Solve
    | Randomize
    | GotRandomSeed Int
    | NodeClicked Int



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotInstances (Ok instances) ->
            ( { model | instances = instances }, Cmd.none )

        GotInstances (Err _) ->
            ( model, Cmd.none )

        SetSource source ->
            let
                newModel =
                    { model
                        | source = source
                        , result = Nothing
                        , manualSet = Set.empty
                        , manualStatus = Nothing
                    }
            in
            ( newModel, loadGraph newModel )

        SetInstanceName name ->
            let
                newModel =
                    { model
                        | instanceName = name
                        , result = Nothing
                        , manualSet = Set.empty
                        , manualStatus = Nothing
                    }
            in
            ( newModel, loadGraph newModel )

        SetGenN s ->
            case String.toInt s of
                Just n ->
                    let
                        newModel =
                            { model
                                | genN = n
                                , result = Nothing
                                , manualSet = Set.empty
                                , manualStatus = Nothing
                            }
                    in
                    ( newModel, loadGraph newModel )

                Nothing ->
                    ( model, Cmd.none )

        SetGenP s ->
            case String.toFloat s of
                Just p ->
                    let
                        newModel =
                            { model
                                | genP = p
                                , result = Nothing
                                , manualSet = Set.empty
                                , manualStatus = Nothing
                            }
                    in
                    ( newModel, loadGraph newModel )

                Nothing ->
                    ( model, Cmd.none )

        SetGenSeed s ->
            case String.toInt s of
                Just seed ->
                    let
                        newModel =
                            { model
                                | genSeed = seed
                                , result = Nothing
                                , manualSet = Set.empty
                                , manualStatus = Nothing
                            }
                    in
                    ( newModel, loadGraph newModel )

                Nothing ->
                    ( model, Cmd.none )

        SetAlgorithm alg ->
            ( { model | algorithm = alg }, Cmd.none )

        SetIterations s ->
            case String.toInt s of
                Just n ->
                    ( { model | iterations = n }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        SetTemperature s ->
            case String.toFloat s of
                Just t ->
                    ( { model | temperature = t }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        SetCooling s ->
            case String.toFloat s of
                Just c ->
                    ( { model | cooling = c }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        GotGraphData (Ok gd) ->
            ( { model | graphData = Just gd }
            , Ports.sendGraphData (encodeGraphPayload gd Nothing Set.empty)
            )

        GotGraphData (Err _) ->
            ( model, Cmd.none )

        GotInstanceGraphData (Ok r) ->
            let
                gd =
                    { n = r.n, edges = r.edges, degrees = r.degrees }
            in
            ( { model | graphData = Just gd }
            , Ports.sendGraphData (encodeGraphPayload gd Nothing Set.empty)
            )

        GotInstanceGraphData (Err _) ->
            ( model, Cmd.none )

        Solve ->
            case model.graphData of
                Nothing ->
                    ( model, Cmd.none )

                Just gd ->
                    let
                        algStr =
                            case model.algorithm of
                                Greedy ->
                                    "greedy"

                                LocalSearch ->
                                    "local_search"

                        params =
                            case model.source of
                                Instance ->
                                    if String.isEmpty model.instanceName then
                                        Nothing

                                    else
                                        Just
                                            { instance = Just model.instanceName
                                            , graphData = Nothing
                                            , algorithm = algStr
                                            , iterations = model.iterations
                                            , temperature = model.temperature
                                            , cooling = model.cooling
                                            , seed = model.genSeed
                                            }

                                Random ->
                                    Just
                                        { instance = Nothing
                                        , graphData = Just { n = gd.n, edges = gd.edges }
                                        , algorithm = algStr
                                        , iterations = model.iterations
                                        , temperature = model.temperature
                                        , cooling = model.cooling
                                        , seed = model.genSeed
                                        }
                    in
                    case params of
                        Just p ->
                            ( { model | solving = True, error = Nothing }
                            , Api.solve p GotSolveResult
                            )

                        Nothing ->
                            ( model, Cmd.none )

        GotSolveResult (Ok r) ->
            let
                newManualSet =
                    Set.fromList r.dominatingSet
            in
            ( { model
                | solving = False
                , result = Just r
                , manualSet = newManualSet
                , manualStatus = Just r.vertexStatus
              }
            , Ports.sendColorUpdate (encodeColorPayload (Just r.vertexStatus) newManualSet)
            )

        GotSolveResult (Err e) ->
            ( { model
                | solving = False
                , error = Just (httpErrorToString e)
              }
            , Cmd.none
            )

        GotValidateResult (Ok v) ->
            ( { model | manualStatus = Just v.vertexStatus }
            , Ports.sendColorUpdate (encodeColorPayload (Just v.vertexStatus) model.manualSet)
            )

        GotValidateResult (Err _) ->
            ( model, Cmd.none )

        Randomize ->
            ( model, Random.generate GotRandomSeed (Random.int 0 99999) )

        GotRandomSeed newSeed ->
            let
                newModel =
                    { model
                        | genSeed = newSeed
                        , result = Nothing
                        , manualSet = Set.empty
                        , manualStatus = Nothing
                    }
            in
            ( newModel, loadGraph newModel )

        NodeClicked nodeId ->
            case model.graphData of
                Nothing ->
                    ( model, Cmd.none )

                Just gd ->
                    let
                        newManualSet =
                            if Set.member nodeId model.manualSet then
                                Set.remove nodeId model.manualSet

                            else
                                Set.insert nodeId model.manualSet

                        validateParams =
                            case model.source of
                                Instance ->
                                    if String.isEmpty model.instanceName then
                                        Nothing

                                    else
                                        Just
                                            { instance = Just model.instanceName
                                            , graphData = Nothing
                                            , dominatingSet = Set.toList newManualSet
                                            }

                                Random ->
                                    Just
                                        { instance = Nothing
                                        , graphData = Just { n = gd.n, edges = gd.edges }
                                        , dominatingSet = Set.toList newManualSet
                                        }
                    in
                    ( { model | manualSet = newManualSet }
                    , case validateParams of
                        Just p ->
                            Api.validate p GotValidateResult

                        Nothing ->
                            Cmd.none
                    )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ viewTopBar
        , div [ class "solver-layout" ]
            [ aside [ class "panel" ]
                [ viewControls
                    { source = model.source
                    , instances = model.instances
                    , instanceName = model.instanceName
                    , genN = model.genN
                    , genP = model.genP
                    , genSeed = model.genSeed
                    , algorithm = model.algorithm
                    , iterations = model.iterations
                    , temperature = model.temperature
                    , cooling = model.cooling
                    , solving = model.solving
                    , onSourceChange = SetSource
                    , onInstanceChange = SetInstanceName
                    , onGenNChange = SetGenN
                    , onGenPChange = SetGenP
                    , onGenSeedChange = SetGenSeed
                    , onAlgorithmChange = SetAlgorithm
                    , onIterationsChange = SetIterations
                    , onTemperatureChange = SetTemperature
                    , onCoolingChange = SetCooling
                    , onSolve = Solve
                    , onRandomize = Randomize
                    }
                ]
            , div [ class "drag-handle" ] []
            , section [ class "graph-area" ]
                [ case model.error of
                    Just err ->
                        div
                            [ style "padding" "0.5rem 1rem"
                            , style "background" "var(--danger)"
                            , style "color" "white"
                            , style "font-size" "0.82rem"
                            , style "text-align" "center"
                            ]
                            [ text err ]

                    Nothing ->
                        text ""
                , div [ id "graph-container", style "flex" "1", style "min-height" "0" ] []
                , if model.graphData == Nothing then
                    div
                        [ style "position" "absolute"
                        , style "inset" "0"
                        , style "display" "flex"
                        , style "flex-direction" "column"
                        , style "align-items" "center"
                        , style "justify-content" "center"
                        , style "color" "var(--text-muted)"
                        , style "font-size" "0.85rem"
                        , style "gap" "0.3rem"
                        ]
                        [ div [ style "font-size" "2rem" ] [ text "\u{1F4CA}" ]
                        , div [] [ text "Generate or load a graph to begin" ]
                        ]

                  else
                    text ""
                , viewBadge
                    { solving = model.solving
                    , hasGraph = model.graphData /= Nothing
                    , hasResult = model.result /= Nothing
                    }
                , viewLegend
                ]
            , div [ class "drag-handle" ] []
            , aside [ class "panel" ]
                [ viewResults model.result model.manualSet model.manualStatus ]
            ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.onNodeClick NodeClicked



-- HELPERS


loadGraph : Model -> Cmd Msg
loadGraph model =
    case model.source of
        Random ->
            Api.generate
                { n = model.genN, p = model.genP, seed = model.genSeed }
                GotGraphData

        Instance ->
            if String.isEmpty model.instanceName then
                Cmd.none

            else
                Api.solve
                    { instance = Just model.instanceName
                    , graphData = Nothing
                    , algorithm = "greedy"
                    , iterations = 0
                    , temperature = 0
                    , cooling = 0
                    , seed = 0
                    }
                    GotInstanceGraphData


httpErrorToString : Http.Error -> String
httpErrorToString err =
    case err of
        Http.BadUrl url ->
            "Bad URL: " ++ url

        Http.Timeout ->
            "Request timed out"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus code ->
            "Server error: " ++ String.fromInt code

        Http.BadBody body ->
            "Bad response: " ++ body



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
