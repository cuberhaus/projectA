module Types exposing (..)

import Json.Decode as D
import Json.Encode as E
import Set exposing (Set)


type Source
    = Random
    | Instance


type Algorithm
    = Greedy
    | LocalSearch


type alias InstanceInfo =
    { name : String
    , file : String
    , n : Int
    , e : Int
    }


type alias GraphData =
    { n : Int
    , edges : List ( Int, Int )
    , degrees : List Int
    }


type alias VertexStatus =
    { id : Int
    , inSet : Bool
    , domNeighbors : Int
    , needed : Int
    , satisfied : Bool
    }


type alias SolveResponse =
    { dominatingSet : List Int
    , size : Int
    , timeMs : Float
    , nodesExplored : Int
    , vertexStatus : List VertexStatus
    , trace : List Int
    , n : Int
    , edges : List ( Int, Int )
    , degrees : List Int
    }


type alias ValidateResponse =
    { valid : Bool
    , size : Int
    , vertexStatus : List VertexStatus
    }



-- JSON Decoders


instanceInfoDecoder : D.Decoder InstanceInfo
instanceInfoDecoder =
    D.map4 InstanceInfo
        (D.field "name" D.string)
        (D.field "file" D.string)
        (D.field "n" D.int)
        (D.field "e" D.int)


edgeDecoder : D.Decoder ( Int, Int )
edgeDecoder =
    D.map2 Tuple.pair
        (D.index 0 D.int)
        (D.index 1 D.int)


graphDataDecoder : D.Decoder GraphData
graphDataDecoder =
    D.map3 GraphData
        (D.field "n" D.int)
        (D.field "edges" (D.list edgeDecoder))
        (D.field "degrees" (D.list D.int))


vertexStatusDecoder : D.Decoder VertexStatus
vertexStatusDecoder =
    D.map5 VertexStatus
        (D.field "id" D.int)
        (D.field "in_set" D.bool)
        (D.field "dom_neighbors" D.int)
        (D.field "needed" D.int)
        (D.field "satisfied" D.bool)


solveResponseDecoder : D.Decoder SolveResponse
solveResponseDecoder =
    D.succeed SolveResponse
        |> andMap (D.field "dominating_set" (D.list D.int))
        |> andMap (D.field "size" D.int)
        |> andMap (D.field "time_ms" D.float)
        |> andMap (D.field "nodes_explored" D.int)
        |> andMap (D.field "vertex_status" (D.list vertexStatusDecoder))
        |> andMap (D.field "trace" (D.list D.int))
        |> andMap (D.field "n" D.int)
        |> andMap (D.field "edges" (D.list edgeDecoder))
        |> andMap (D.field "degrees" (D.list D.int))


validateResponseDecoder : D.Decoder ValidateResponse
validateResponseDecoder =
    D.map3 ValidateResponse
        (D.field "valid" D.bool)
        (D.field "size" D.int)
        (D.field "vertex_status" (D.list vertexStatusDecoder))


andMap : D.Decoder a -> D.Decoder (a -> b) -> D.Decoder b
andMap =
    D.map2 (|>)



-- JSON Encoders (for ports)


encodeEdge : ( Int, Int ) -> E.Value
encodeEdge ( s, t ) =
    E.list E.int [ s, t ]


encodeVertexStatus : VertexStatus -> E.Value
encodeVertexStatus vs =
    E.object
        [ ( "id", E.int vs.id )
        , ( "inSet", E.bool vs.inSet )
        , ( "domNeighbors", E.int vs.domNeighbors )
        , ( "needed", E.int vs.needed )
        , ( "satisfied", E.bool vs.satisfied )
        ]


encodeGraphPayload : GraphData -> Maybe (List VertexStatus) -> Set Int -> E.Value
encodeGraphPayload gd status manualSet =
    E.object
        [ ( "n", E.int gd.n )
        , ( "edges", E.list encodeEdge gd.edges )
        , ( "degrees", E.list E.int gd.degrees )
        , ( "vertexStatus"
          , case status of
                Just vs ->
                    E.list encodeVertexStatus vs

                Nothing ->
                    E.null
          )
        , ( "manualSet", E.list E.int (Set.toList manualSet) )
        ]


encodeColorPayload : Maybe (List VertexStatus) -> Set Int -> E.Value
encodeColorPayload status manualSet =
    E.object
        [ ( "vertexStatus"
          , case status of
                Just vs ->
                    E.list encodeVertexStatus vs

                Nothing ->
                    E.null
          )
        , ( "manualSet", E.list E.int (Set.toList manualSet) )
        ]
