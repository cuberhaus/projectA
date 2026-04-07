module Api exposing (generate, getInstances, solve, validate)

import Http
import Json.Decode as D
import Json.Encode as E
import Types exposing (..)


getInstances : (Result Http.Error (List InstanceInfo) -> msg) -> Cmd msg
getInstances toMsg =
    Http.get
        { url = "/api/instances"
        , expect = Http.expectJson toMsg (D.list instanceInfoDecoder)
        }


generate : { n : Int, p : Float, seed : Int } -> (Result Http.Error GraphData -> msg) -> Cmd msg
generate params toMsg =
    Http.post
        { url = "/api/generate"
        , body =
            Http.jsonBody
                (E.object
                    [ ( "n", E.int params.n )
                    , ( "p", E.float params.p )
                    , ( "seed", E.int params.seed )
                    ]
                )
        , expect = Http.expectJson toMsg graphDataDecoder
        }


type alias SolveParams =
    { instance : Maybe String
    , graphData : Maybe { n : Int, edges : List ( Int, Int ) }
    , algorithm : String
    , iterations : Int
    , temperature : Float
    , cooling : Float
    , seed : Int
    }


solve : SolveParams -> (Result Http.Error SolveResponse -> msg) -> Cmd msg
solve params toMsg =
    let
        base =
            [ ( "algorithm", E.string params.algorithm )
            , ( "iterations", E.int params.iterations )
            , ( "temperature", E.float params.temperature )
            , ( "cooling", E.float params.cooling )
            , ( "seed", E.int params.seed )
            ]

        instanceField =
            case params.instance of
                Just name ->
                    [ ( "instance", E.string name ) ]

                Nothing ->
                    []

        graphField =
            case params.graphData of
                Just gd ->
                    [ ( "graph_data"
                      , E.object
                            [ ( "n", E.int gd.n )
                            , ( "edges", E.list encodeEdge gd.edges )
                            ]
                      )
                    ]

                Nothing ->
                    []
    in
    Http.post
        { url = "/api/solve"
        , body = Http.jsonBody (E.object (base ++ instanceField ++ graphField))
        , expect = Http.expectJson toMsg solveResponseDecoder
        }


validate :
    { instance : Maybe String
    , graphData : Maybe { n : Int, edges : List ( Int, Int ) }
    , dominatingSet : List Int
    }
    -> (Result Http.Error ValidateResponse -> msg)
    -> Cmd msg
validate params toMsg =
    let
        base =
            [ ( "dominating_set", E.list E.int params.dominatingSet ) ]

        instanceField =
            case params.instance of
                Just name ->
                    [ ( "instance", E.string name ) ]

                Nothing ->
                    []

        graphField =
            case params.graphData of
                Just gd ->
                    [ ( "graph_data"
                      , E.object
                            [ ( "n", E.int gd.n )
                            , ( "edges", E.list encodeEdge gd.edges )
                            ]
                      )
                    ]

                Nothing ->
                    []
    in
    Http.post
        { url = "/api/validate"
        , body = Http.jsonBody (E.object (base ++ instanceField ++ graphField))
        , expect = Http.expectJson toMsg validateResponseDecoder
        }
