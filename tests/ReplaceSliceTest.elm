module ReplaceSliceTest exposing (replaceSliceTest)

import Expect
import Fuzz exposing (..)
import Random
import Shrink
import String
import String.Extra exposing (..)
import Test exposing (..)


replaceSliceTest : Test
replaceSliceTest =
    describe "replaceSlice"
        [ fuzz replaceSliceProducer "Result contains the substitution string" <|
            \( ( string, sub ), ( start, end ) ) ->
                case string of
                    "" ->
                        replaceSlice sub start end string
                            |> Expect.equal sub

                    _ ->
                        replaceSlice sub start end string
                            |> String.contains sub
                            |> Expect.true "The slice was not subtituted"
        , fuzz replaceSliceProducer "Result string has the length of the substitution + string after removing the slice" <|
            \( ( string, sub ), ( start, end ) ) ->
                case string of
                    "" ->
                        replaceSlice sub start end string
                            |> String.length
                            |> Expect.equal (String.length sub)

                    _ ->
                        replaceSlice sub start end string
                            |> String.length
                            |> Expect.equal ((String.length string - (end - start)) + String.length sub)
        , fuzz replaceSliceProducer "Start of the original string remains the same" <|
            \( ( string, sub ), ( start, end ) ) ->
                case string of
                    "" ->
                        replaceSlice sub start end string
                            |> Expect.equal sub

                    _ ->
                        replaceSlice sub start end string
                            |> String.slice 0 start
                            |> Expect.equal (String.slice 0 start string)
        , fuzz replaceSliceProducer "End of the original string remains the same" <|
            \( ( string, sub ), ( start, end ) ) ->
                let
                    replaced =
                        replaceSlice sub start end string
                in
                case string of
                    "" ->
                        replaced
                            |> Expect.equal sub

                    _ ->
                        replaced
                            |> String.slice (start + String.length sub) (String.length replaced)
                            |> Expect.equal (String.slice end (String.length string) string)
        ]


withChar : List Char -> Random.Generator Char
withChar ch =
    Random.andThen identity <|
        Random.uniform (Random.map Char.fromCode (Random.int 97 122)) <|
            Random.map Char.fromCode (Random.int 65 90)
                :: List.map Random.constant ch


lowercaseLetter : Random.Generator Char
lowercaseLetter =
    Random.map (\n -> Char.fromCode (n + 97)) (Random.int 0 25)


randomString : Random.Generator String
randomString =
    Random.int 1 1000
        |> Random.andThen (\len -> Random.list len lowercaseLetter)
        |> Random.map String.fromList


replaceSliceProducer : Fuzzer ( ( String, String ), ( Int, Int ) )
replaceSliceProducer =
    let
        producer =
            Random.map2 Tuple.pair randomString randomString
                |> Random.andThen (\( str, sub ) -> Random.pair (Random.constant ( str, sub )) (Random.int 0 <| String.length str))
                |> Random.andThen (\( ( str, sub ), start ) -> Random.pair (Random.constant ( str, sub )) (Random.pair (Random.constant start) (Random.int start <| String.length str)))
    in
    Fuzz.custom producer Shrink.noShrink
