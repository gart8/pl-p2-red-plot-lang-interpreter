Red [
    Needs: 'View
]

#include %grammar.red
#include %parser.red
#include %views.red

source-field: none
result-area: none

process-input: does [
    source: source-field/text
    normalized: uppercase trim source
    stop-position: find normalized "STOP"
    start-position: find normalized "START"
    end-position: find normalized "END"
    if stop-position [
        stop-is-outside?: any [
            none? start-position
            none? end-position
            (index? stop-position) < (index? start-position)
            (index? stop-position) > (index? end-position)
        ]
        if stop-is-outside? [quit]
    ]
    result-area/text: ""
    show result-area
    last-valid: false
    if empty? (trim source) [
        result-area/text: "Error: enter a sentence."
        show result-area
        return true
    ]
    last-valid: parse-program source
    if last-valid [
        result-area/text: rejoin [derivation-text "^/Derivation successful."]
    ]
    if not last-valid [
        result-area/text: rejoin [derivation-text "^/Syntax error: " parse-error]
    ]
    show result-area
]

main: does [
    view layout [
        title "Red Plot Language Interpreter"
        backdrop snow
        panel 610x900 [
            below
            text "Red Plot Language Interpreter" font-size 22
            text "Enter a graph sentence, then analyze it. Type STOP to exit."
            text "Example: start grid b4; bar c6,3; line a1,j8 end"
            text "BNF grammar" font-size 16
            grammar-area: area 600x250 grammar-text
            text "Input sentence" font-size 16
            source-field: field 600 "start grid j9; bar a3,1; fill a3; line b2,h7; bar b5,1; line a1,j8; bar c4,1; bar d8,1; fill c4; fill d8 end" on-enter [process-input]
            button "Analyze sentence" [process-input]
            result-area: area 600x250 "Derivation output appears here."
            button "Show parse tree" [if last-valid [show-parse-tree-window]]
            button "Show graph" [if last-valid [draw-output]]
            button "Exit" [quit]
        ]
    ]
]

main
