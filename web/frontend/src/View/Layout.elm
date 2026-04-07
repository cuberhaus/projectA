module View.Layout exposing (viewBadge, viewLegend, viewTopBar)

import Html exposing (..)
import Html.Attributes exposing (class, style)


viewTopBar : Html msg
viewTopBar =
    header [ class "top-bar" ]
        [ h1 []
            [ text "MPIDS"
            , span [] [ text "Graph Dominance Solver" ]
            ]
        ]


viewLegend : Html msg
viewLegend =
    div [ class "legend" ]
        [ span [ class "legend-item" ]
            [ span [ class "legend-dot", style "background" "#22c55e" ] []
            , text " In D"
            ]
        , span [ class "legend-item" ]
            [ span [ class "legend-dot", style "background" "#3b82f6" ] []
            , text " Satisfied"
            ]
        , span [ class "legend-item" ]
            [ span [ class "legend-dot", style "background" "#ef4444" ] []
            , text " Unsatisfied"
            ]
        ]


viewBadge : { solving : Bool, hasGraph : Bool, hasResult : Bool } -> Html msg
viewBadge cfg =
    if cfg.solving then
        div [ class "badge badge-solving" ] [ text "Solving..." ]

    else if cfg.hasGraph && not cfg.hasResult then
        div [ class "badge badge-manual" ] [ text "Interactive" ]

    else
        text ""
