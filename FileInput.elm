module FileInput exposing (
    Model, File,
    Msg, update,
    view
  )

{-|
 Use `<input type="file">` from Elm

# Model
@docs File, Model

# Update
@docs Msg, update

# View
@docs view
-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.App as App
import Json.Decode exposing ((:=))
import Json.Decode as Json
import Task exposing (Task)

import Native.ReadFile

readFile : File -> Cmd Msg
readFile f =
  Native.ReadFile.readFile f
    |> Task.perform
          (\errmsg -> FileRead {f|contents = Err errmsg})
          (\filecontents -> FileRead {f | contents = Ok filecontents})

{-|Represents a file and its metainformation

`name` is the name of the file.

`mime` is its MIME type.

`size` is its size in bytes.

The `contents` field is filled with an `Ok [filecontents]`
only once the file has been read, which may take some time.
While the file is being read, `contents = Err "Not loaded yet"`.
-}
type alias File = {
    name : String,
    mime : String,
    size : Int,
    contents : Result String String
  }

{-|-}
type alias Model = List File

{-|-}
type Msg = FileChanged Model | FileRead File

{-|Represents an `<input type="file">`-}
view : Html Msg
view =
  input
    [
      type' "file",
      multiple True,
      on "change" fromJson
    ] []

{-| Read an object of the form
{
  "length" : 2
  "0" : Object0
  "1" : Object1
}
-}
jsonPseudoList : Json.Decoder a -> Json.Decoder (List a)
jsonPseudoList decoder =
  let
    addvalue num list =
      Json.map (\val -> val::list) ((toString num) := decoder)
    fromLength length =
      List.foldr
        (\num prevdec -> prevdec `Json.andThen` (addvalue num))
        (Json.succeed [])
        [0..length-1]
  in
  ("length" := Json.int) `Json.andThen` fromLength

fromJson : Json.Decoder Msg
fromJson =
  let
    fileinfo =
      Json.object4 (File)
          ("name" := Json.string)
          ("type" := Json.string)
          ("size" := Json.int)
          (Json.succeed (Err "Not loaded yet"))
    findfiles = Json.at ["target", "files"] (jsonPseudoList fileinfo)
  in
    findfiles `Json.andThen` (\f -> Json.succeed (FileChanged f))

{-|-}
update : Msg -> Model -> (Model, Cmd Msg)
update msg files =
  case msg of
    FileChanged files' ->
      files' ! (List.map readFile files')
    FileRead f ->
      let
        replacefile file =
            if file.name == f.name && file.size == f.size then f else file
      in
        (List.map replacefile files) ! []

subscriptions : Model -> Sub Msg
subscriptions files = Sub.none

main: Program Never
main = App.program {
    init = [] ! [],
    view  = \files -> div [] [
              view,
              text <| toString <| files
            ],
    update = update,
    subscriptions = subscriptions
  }
