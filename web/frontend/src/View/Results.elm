module View.Results exposing (viewResults)

import Html exposing (..)
import Html.Attributes as A exposing (class, style)
import Set exposing (Set)
import Svg
import Svg.Attributes as SA
import Types exposing (..)


viewResults : Maybe SolveResponse -> Set Int -> Maybe (List VertexStatus) -> Html msg
viewResults result manualSet manualStatus =
    let
        status =
            case manualStatus of
                Just ms ->
                    Just ms

                Nothing ->
                    Maybe.map .vertexStatus result

        setSize =
            case result of
                Just r ->
                    r.size

                Nothing ->
                    Set.size manualSet

        satisfied =
            case status of
                Just vs ->
                    List.length (List.filter .satisfied vs)

                Nothing ->
                    0

        total =
            case status of
                Just vs ->
                    List.length vs

                Nothing ->
                    0

        allSatisfied =
            case status of
                Just _ ->
                    satisfied == total

                Nothing ->
                    False
    in
    case ( status, result ) of
        ( Nothing, Nothing ) ->
            div [ class "empty-state", style "font-size" "0.82rem" ]
                [ div [ style "font-size" "1.5rem" ] [ text "\u{1F50D}" ]
                , div []
                    [ text "Click "
                    , b [] [ text "Solve" ]
                    , text " or toggle nodes manually"
                    ]
                ]

        _ ->
            div []
                [ div [ class "section-title" ] [ text "Results" ]
                , div [ class "stats-grid" ]
                    ([ div [ class "stat-card" ]
                        [ div [ class "stat-value" ] [ text (String.fromInt setSize) ]
                        , div [ class "stat-label" ] [ text "|D| Size" ]
                        ]
                     , div [ class "stat-card" ]
                        [ div
                            [ class "stat-value"
                            , style "color"
                                (if allSatisfied then
                                    "var(--success)"

                                 else
                                    "var(--danger)"
                                )
                            ]
                            [ text (String.fromInt satisfied ++ "/" ++ String.fromInt total) ]
                        , div [ class "stat-label" ] [ text "Satisfied" ]
                        ]
                     ]
                        ++ (case result of
                                Just r ->
                                    [ div [ class "stat-card" ]
                                        [ div [ class "stat-value" ]
                                            [ text (formatMs r.timeMs)
                                            , span [ style "font-size" "0.65rem", style "color" "var(--text-muted)" ] [ text "ms" ]
                                            ]
                                        , div [ class "stat-label" ] [ text "Time" ]
                                        ]
                                    , div [ class "stat-card" ]
                                        [ div [ class "stat-value" ] [ text (String.fromInt r.nodesExplored) ]
                                        , div [ class "stat-label" ] [ text "Explored" ]
                                        ]
                                    ]

                                Nothing ->
                                    []
                           )
                    )
                , div
                    [ style "margin-top" "0.5rem"
                    , style "padding" "0.4rem 0.6rem"
                    , style "border-radius" "var(--radius-sm)"
                    , style "background"
                        (if allSatisfied then
                            "rgba(34,197,94,0.1)"

                         else
                            "rgba(239,68,68,0.1)"
                        )
                    , style "border"
                        ("1px solid "
                            ++ (if allSatisfied then
                                    "rgba(34,197,94,0.3)"

                                else
                                    "rgba(239,68,68,0.3)"
                               )
                        )
                    , style "font-size" "0.78rem"
                    , style "font-weight" "600"
                    , style "color"
                        (if allSatisfied then
                            "var(--success)"

                         else
                            "var(--danger)"
                        )
                    ]
                    [ text
                        (if allSatisfied then
                            "Valid PIDS"

                         else
                            "Not a valid PIDS"
                        )
                    ]
                , case result of
                    Just r ->
                        viewTraceChart r.trace

                    Nothing ->
                        text ""
                , case status of
                    Just vs ->
                        viewUnsatisfied vs

                    Nothing ->
                        text ""
                ]


formatMs : Float -> String
formatMs ms =
    let
        r =
            round (ms * 10)
    in
    String.fromInt (r // 10) ++ "." ++ String.fromInt (modBy 10 r)


viewTraceChart : List Int -> Html msg
viewTraceChart trace =
    if List.length trace < 2 then
        text ""

    else
        let
            w =
                250.0

            h =
                60.0

            pad =
                2.0

            vals =
                List.map toFloat trace

            maxVal =
                Maybe.withDefault 1 (List.maximum vals)

            minVal =
                Maybe.withDefault 0 (List.minimum vals)

            range =
                if maxVal - minVal == 0 then
                    1

                else
                    maxVal - minVal

            len =
                List.length trace

            points =
                List.indexedMap
                    (\i v ->
                        let
                            x =
                                pad + (toFloat i / toFloat (len - 1)) * (w - 2 * pad)

                            y =
                                pad + (1 - (toFloat v - minVal) / range) * (h - 2 * pad)
                        in
                        String.fromFloat x ++ "," ++ String.fromFloat y
                    )
                    trace
                    |> String.join " "
        in
        div [ class "trace-chart" ]
            [ div [ class "section-title" ] [ text "Set Size Trace" ]
            , Svg.svg
                [ SA.viewBox ("0 0 " ++ String.fromFloat w ++ " " ++ String.fromFloat h)
                , style "background" "var(--bg-card)"
                , style "border-radius" "var(--radius-sm)"
                , style "border" "1px solid var(--border)"
                ]
                [ Svg.polyline
                    [ SA.points points
                    , SA.fill "none"
                    , SA.stroke "var(--accent)"
                    , SA.strokeWidth "1.5"
                    ]
                    []
                ]
            ]


viewUnsatisfied : List VertexStatus -> Html msg
viewUnsatisfied status =
    let
        unsatisfied =
            List.filter (\s -> not s.satisfied) status
    in
    div []
        [ div [ class "section-title" ] [ text "Unsatisfied Vertices" ]
        , if List.isEmpty unsatisfied then
            div [ style "font-size" "0.78rem", style "color" "var(--text-muted)" ]
                [ text "None — all vertices satisfied" ]

          else
            div
                [ style "max-height" "200px"
                , style "overflow" "auto"
                , style "font-size" "0.75rem"
                , style "font-family" "var(--font-mono)"
                ]
                (List.map
                    (\s ->
                        div
                            [ style "padding" "0.2rem 0.4rem"
                            , style "background" "var(--bg-card)"
                            , style "border-radius" "var(--radius-sm)"
                            , style "border" "1px solid var(--border)"
                            , style "margin-bottom" "0.2rem"
                            ]
                            [ text ("v" ++ String.fromInt s.id ++ ": " ++ String.fromInt s.domNeighbors ++ "/" ++ String.fromInt s.needed ++ " neighbors") ]
                    )
                    unsatisfied
                )
        ]
