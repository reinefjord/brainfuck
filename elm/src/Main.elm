module Main exposing (..)

import Array exposing (Array)
import Browser
import Char exposing (fromCode)
import Debug
import Html exposing
  ( Html
  , Attribute
  , button
  , div
  , input
  , text
  , textarea
  )
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)



-- MAIN

main =
  Browser.sandbox
  { init = init
  , view = view
  , update = update
  }


-- MODEL

type DoToken
  = IncrementPointer
  | DecrementPointer
  | IncrementCell
  | DecrementCell
  | Print
  | Store

type LoopToken
  = LoopStart
  | LoopEnd

type Token
  = TDoToken DoToken
  | TLoopToken LoopToken

type Instruction
  = Do DoToken
  | Loop (List Instruction)


type alias Tape =
  { pointer: Int
  , data: Array Int
  }


type alias Model =
  { input: String
  , output: String
  , tape: Tape
  }


initTape : Tape
initTape =
  { pointer = 0
  , data = Array.repeat 30000 0
  }


init : Model
init =
  { input = ""
  , output = ""
  , tape = initTape
  }


-- UPDATE

type Clicks
  = Run


type Msg
  = Input String
  | Click Clicks


update : Msg -> Model -> Model
update msg model =
  case msg of
    Input input ->
      { model | input = input }

    Click Run ->
      start model


-- VIEW

view : Model -> Html Msg
view model =
  div [ style "padding" "1rem" ]
    [ textarea
      [ placeholder "Input program"
      , value model.input
      , cols 80
      , rows 20
      , onInput Input
      ] []
    , div
      [ style "margin-top" "1rem" ]
      [ button [ onClick (Click Run) ]
        [ text "Run" ]
      ]
    , div
      [ style "margin-top" "1rem" ]
      [ text model.output ]
    ]


tokenize : String -> List Token
tokenize s =
  let
    tokenMap c =
      case c of
        '>' -> Just (TDoToken IncrementPointer)
        '<' -> Just (TDoToken DecrementPointer)
        '+' -> Just (TDoToken IncrementCell)
        '-' -> Just (TDoToken DecrementCell)
        '.' -> Just (TDoToken Print)
        ',' -> Just (TDoToken Store)
        '[' -> Just (TLoopToken LoopStart)
        ']' -> Just (TLoopToken LoopEnd)
        _ -> Nothing

    chars = String.toList s

  in
    List.filterMap tokenMap chars


parse : List Token -> (List Instruction, List Token)
parse tokens =
  let
    tail =
      case List.tail tokens of
        Just t ->
          t
        Nothing ->
          []

    (instructions, toParse) =
      case List.head tokens of
        Just (TLoopToken LoopStart) ->
          let
            (is, ts) = parse tail
            (iss, tss) = parse ts
            isss = Loop is :: iss
          in
            (isss, tss)

        Just (TLoopToken LoopEnd) ->
          ([], tail)

        Just (TDoToken token) ->
          let
            (is, ts) = parse tail
            iss = Do token :: is
          in
            (iss, ts)

        Nothing ->
          ([], [])

  in
    (instructions, toParse)


getCell : Tape -> Int
getCell tape =
  Maybe.withDefault 0 <| Array.get tape.pointer tape.data


setCell : Tape -> Int -> Tape
setCell tape byte =
  { tape
  | data = Array.set tape.pointer byte tape.data
  }


incrementPointer : Model -> Model
incrementPointer model =
  let
    tape = model.tape
    newTape = { tape | pointer = tape.pointer + 1 }
  in
    { model | tape = newTape }


decrementPointer : Model -> Model
decrementPointer model =
  let
    tape = model.tape
    newTape = { tape | pointer = tape.pointer - 1 }
  in
    { model | tape = newTape }


incrementCell : Model -> Model
incrementCell model =
  let
    tape = model.tape
    cell = getCell tape
    newTape = setCell tape <| modBy 256 (cell + 1)
  in
    { model | tape = newTape }


decrementCell : Model -> Model
decrementCell model =
  let
    tape = model.tape
    cell = getCell tape
    newTape = setCell tape <| modBy 256 (cell - 1)
  in
    { model | tape = newTape }


print : Model -> Model
print model =
  let
    cell = getCell model.tape
    newOutput = model.output ++ (fromCode cell |> String.fromChar)
  in
    { model | output = newOutput }


store : Model -> Model
store model =
  model


loop : Model -> List Instruction -> Model
loop model instructions =
  let
    cell = getCell model.tape
    newModel =
      if cell == 0 then
        model
      else
        loop (run model instructions) instructions
  in
    newModel


execute : Instruction -> Model -> Model
execute instruction model =
  let
    newModel =
      case instruction of
        Do IncrementPointer -> incrementPointer model
        Do DecrementPointer -> decrementPointer model
        Do IncrementCell -> incrementCell model
        Do DecrementCell -> decrementCell model
        Do Print -> print model
        Do Store -> store model
        Loop instructions -> loop model instructions
  in
    newModel


run : Model -> List Instruction -> Model
run model instructions =
  List.foldl execute model instructions


start : Model -> Model
start model =
  let
    tokens = tokenize model.input
    (instructions, _) = parse tokens
    resetModel =
      { model
      | output = ""
      , tape = initTape
      }
    newModel = run resetModel instructions
  in
    newModel
