module View.Controls exposing (viewControls)

import Html exposing (..)
import Html.Attributes as A exposing (class, disabled, style, value)
import Html.Events exposing (onClick, onInput)
import Types exposing (..)


type alias Config msg =
    { source : Source
    , instances : List InstanceInfo
    , instanceName : String
    , genN : Int
    , genP : Float
    , genSeed : Int
    , algorithm : Algorithm
    , iterations : Int
    , temperature : Float
    , cooling : Float
    , solving : Bool
    , onSourceChange : Source -> msg
    , onInstanceChange : String -> msg
    , onGenNChange : String -> msg
    , onGenPChange : String -> msg
    , onGenSeedChange : String -> msg
    , onAlgorithmChange : Algorithm -> msg
    , onIterationsChange : String -> msg
    , onTemperatureChange : String -> msg
    , onCoolingChange : String -> msg
    , onSolve : msg
    , onRandomize : msg
    }


viewControls : Config msg -> Html msg
viewControls cfg =
    div []
        [ div [ class "section-title" ] [ text "Graph Source" ]
        , div [ class "form-group" ]
            [ select
                [ class "form-select"
                , value
                    (case cfg.source of
                        Random ->
                            "random"

                        Instance ->
                            "instance"
                    )
                , onInput
                    (\v ->
                        if v == "instance" then
                            cfg.onSourceChange Instance

                        else
                            cfg.onSourceChange Random
                    )
                ]
                [ option [ A.value "random" ] [ text "Random G(n,p)" ]
                , option [ A.value "instance" ] [ text "Preset Instance" ]
                ]
            ]
        , case cfg.source of
            Instance ->
                div [ class "form-group", style "margin-top" "0.4rem" ]
                    [ label [ class "form-label" ] [ text "Instance" ]
                    , select
                        [ class "form-select"
                        , value cfg.instanceName
                        , onInput cfg.onInstanceChange
                        ]
                        (option [ A.value "" ] [ text "— select —" ]
                            :: List.map
                                (\i ->
                                    option [ A.value i.name ]
                                        [ text (i.name ++ " (" ++ String.fromInt i.n ++ "V, " ++ String.fromInt i.e ++ "E)") ]
                                )
                                cfg.instances
                        )
                    ]

            Random ->
                div [ class "controls-grid", style "margin-top" "0.4rem" ]
                    [ div [ class "form-group" ]
                        [ label [ class "form-label" ] [ text "Nodes (N)" ]
                        , input
                            [ class "form-input"
                            , A.type_ "number"
                            , A.min "3"
                            , A.max "300"
                            , value (String.fromInt cfg.genN)
                            , onInput cfg.onGenNChange
                            ]
                            []
                        ]
                    , div [ class "form-group" ]
                        [ label [ class "form-label" ] [ text "Edge prob (p)" ]
                        , input
                            [ class "form-input"
                            , A.type_ "number"
                            , A.min "0"
                            , A.max "1"
                            , A.step "0.01"
                            , value (String.fromFloat cfg.genP)
                            , onInput cfg.onGenPChange
                            ]
                            []
                        ]
                    , div [ class "form-group" ]
                        [ label [ class "form-label" ] [ text "Seed" ]
                        , input
                            [ class "form-input"
                            , A.type_ "number"
                            , value (String.fromInt cfg.genSeed)
                            , onInput cfg.onGenSeedChange
                            ]
                            []
                        ]
                    ]
        , div [ class "section-title" ] [ text "Algorithm" ]
        , div [ class "form-group" ]
            [ select
                [ class "form-select"
                , value
                    (case cfg.algorithm of
                        Greedy ->
                            "greedy"

                        LocalSearch ->
                            "local_search"
                    )
                , onInput
                    (\v ->
                        if v == "local_search" then
                            cfg.onAlgorithmChange LocalSearch

                        else
                            cfg.onAlgorithmChange Greedy
                    )
                ]
                [ option [ A.value "greedy" ] [ text "Greedy" ]
                , option [ A.value "local_search" ] [ text "Local Search (SA)" ]
                ]
            ]
        , case cfg.algorithm of
            LocalSearch ->
                div [ class "controls-grid", style "margin-top" "0.4rem" ]
                    [ div [ class "form-group" ]
                        [ label [ class "form-label" ] [ text "Iterations" ]
                        , input
                            [ class "form-input"
                            , A.type_ "number"
                            , A.min "100"
                            , A.max "50000"
                            , A.step "100"
                            , value (String.fromInt cfg.iterations)
                            , onInput cfg.onIterationsChange
                            ]
                            []
                        ]
                    , div [ class "form-group" ]
                        [ label [ class "form-label" ] [ text "Temperature" ]
                        , input
                            [ class "form-input"
                            , A.type_ "number"
                            , A.min "0"
                            , A.step "1"
                            , value (String.fromFloat cfg.temperature)
                            , onInput cfg.onTemperatureChange
                            ]
                            []
                        ]
                    , div [ class "form-group" ]
                        [ label [ class "form-label" ] [ text "Cooling" ]
                        , input
                            [ class "form-input"
                            , A.type_ "number"
                            , A.min "0.9"
                            , A.max "1"
                            , A.step "0.001"
                            , value (String.fromFloat cfg.cooling)
                            , onInput cfg.onCoolingChange
                            ]
                            []
                        ]
                    ]

            Greedy ->
                text ""
        , div [ class "btn-row" ]
            [ button
                [ class "btn btn-primary"
                , style "flex" "1"
                , onClick cfg.onSolve
                , disabled cfg.solving
                ]
                [ text
                    (if cfg.solving then
                        "Solving..."

                     else
                        "Solve"
                    )
                ]
            , button
                [ class "btn btn-secondary"
                , onClick cfg.onRandomize
                , disabled cfg.solving
                ]
                [ text "Randomize" ]
            ]
        , div [ style "margin-top" "0.75rem", style "font-size" "0.72rem", style "color" "var(--text-muted)" ]
            [ text "Click nodes to manually toggle them in/out of the dominating set." ]
        ]
