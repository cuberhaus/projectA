port module Ports exposing (onNodeClick, sendColorUpdate, sendGraphData)

import Json.Encode as E


port sendGraphData : E.Value -> Cmd msg


port sendColorUpdate : E.Value -> Cmd msg


port onNodeClick : (Int -> msg) -> Sub msg
