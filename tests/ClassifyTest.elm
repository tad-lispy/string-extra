module ClassifyTest exposing (classifyTest)

import Char
import Expect
import Fuzz exposing (..)
import Random
import Regex
import Shrink
import String exposing (replace, uncons)
import String.Extra exposing (..)
import Test exposing (..)
import Tuple exposing (first, second)


classifyTest : Test
classifyTest =
    describe "classify"
        [ fuzz string "It does not contain non-word characters" <|
            \string ->
                classify string
                    |> Regex.contains (Regex.fromString "[\\W]" |> Maybe.withDefault Regex.never)
                    |> Expect.false "Non word characters detected"
        , fuzz (latinWords 1 10) "It starts with an uppercase letter" <|
            \string ->
                string
                    |> classify
                    |> uncons
                    |> Maybe.map first
                    |> Expect.equal (string |> String.trim |> String.toUpper |> uncons |> Maybe.map first)
        , fuzz (validWords 1 10) "It is camelized once replaced non word charactes with a compatible string" <|
            \string ->
                string
                    |> classify
                    |> uncons
                    |> Maybe.map second
                    |> Expect.equal (string |> replace "." "-" |> camelize |> uncons |> Maybe.map second)
        ]


charGenerator : Random.Generator Char
charGenerator =
    Random.uniform latinChar1 [ latinChar2 ]
        |> Random.andThen identity


validCharGenerator : Random.Generator Char
validCharGenerator =
    Random.andThen identity <|
        Random.uniform latinChar1 <|
            [ latinChar2, Random.map Char.fromCode (Random.int 45 46), Random.constant (Char.fromCode 95) ]


latinChar1 : Random.Generator Char
latinChar1 =
    Random.map Char.fromCode (Random.int 97 122)


latinChar2 : Random.Generator Char
latinChar2 =
    Random.map Char.fromCode (Random.int 65 90)


latinWords : Int -> Int -> Fuzzer String
latinWords min max =
    let
        producer =
            Random.int min max |> Random.andThen (\i -> Random.map String.fromList (Random.list i charGenerator))
    in
    custom producer Shrink.string


validWords : Int -> Int -> Fuzzer String
validWords min max =
    let
        producer =
            Random.int min max |> Random.andThen (\i -> Random.map String.fromList (Random.list i validCharGenerator))
    in
    custom producer Shrink.string
