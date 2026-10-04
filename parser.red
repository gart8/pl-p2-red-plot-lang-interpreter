Red []

letter: charset valid-letters
digit: charset valid-digits
whitespace-character: charset [#" " #"^(tab)" #"^(line)"]
whitespace: [some whitespace-character]
optional-whitespace: [any whitespace-character]

compact-coordinate: func [coordinate [string!]][
    coordinate: replace/all coordinate " " ""
    coordinate: replace/all coordinate "^(tab)" ""
    coordinate: replace/all coordinate "^(line)" ""
    coordinate
]

bar-rule: [
    "bar" whitespace [letter optional-whitespace digit] optional-whitespace "," optional-whitespace digit
]

line-rule: [
    "line" whitespace [letter optional-whitespace digit] optional-whitespace "," optional-whitespace [letter optional-whitespace digit]
]

grid-rule: [
    "grid" whitespace [letter optional-whitespace digit]
]

fill-rule: [
    "fill" whitespace [letter optional-whitespace digit]
]

plot-rule: [bar-rule | line-rule | grid-rule | fill-rule]

graph-rule: [
    optional-whitespace "start" whitespace
    collect set plot-texts [
        keep copy plot-value plot-rule
        any [optional-whitespace ";" optional-whitespace keep copy plot-value plot-rule]
    ]
    optional-whitespace "end" optional-whitespace end
]

store-plot: func [plot-value [string!]][
    parse plot-value [
        "bar" whitespace copy coordinate [letter optional-whitespace digit] optional-whitespace "," optional-whitespace copy width digit
        (append/only plots reduce ["bar" compact-coordinate coordinate width])
        |
        "line" whitespace copy start-coordinate [letter optional-whitespace digit] optional-whitespace "," optional-whitespace copy end-coordinate [letter optional-whitespace digit]
        (append/only plots reduce ["line" compact-coordinate start-coordinate compact-coordinate end-coordinate])
        |
        "grid" whitespace copy coordinate [letter optional-whitespace digit]
        (append/only plots reduce ["grid" compact-coordinate coordinate])
        |
        "fill" whitespace copy coordinate [letter optional-whitespace digit]
        (append/only plots reduce ["fill" compact-coordinate coordinate])
    ]
]

format-plot: func [plot [block!]][
    value: rejoin [plot/1 " " compact-coordinate plot/2]
    if (length? plot) > 2 [append value rejoin ["," compact-coordinate plot/3]]
    value
]

record-derivation: func [value [string!]][
    append derivation rejoin ["⇒ " value]
]

plot-production: func [plot [block!]][
    production: rejoin [plot/1 " <x><y>"]
    if plot/1 = "bar" [production: "bar <x><y>,<y>"]
    if plot/1 = "line" [production: "line <x><y>,<x><y>"]
    if plot/1 = "grid" [production: "grid <x><y>"]
    if plot/1 = "fill" [production: "fill <x><y>"]
    production
]

derive-plot: func [current [string!] plot [block!]][
    current: replace current "<plot>" plot-production plot
    record-derivation current
    current: replace current "<x>" plot/2/1
    record-derivation current
    current: replace current "<y>" plot/2/2
    record-derivation current
    if plot/1 = "bar" [
        current: replace current "<y>" plot/3
        record-derivation current
    ]
    if plot/1 = "line" [
        current: replace current "<x>" plot/3/1
        record-derivation current
        current: replace current "<y>" plot/3/2
        record-derivation current
    ]
    current
]

parse-program: func [source [string!]][
    clear plots
    clear plot-texts
    clear derivation
    parse-error: ""
    source: lowercase trim source
    if empty? source [parse-error: "A graph sentence is required." return false]
    if not parse source graph-rule [
        parse-error: "Expected: start <plot> ; <plot> end, using coordinates such as a1."
        return false
    ]
    foreach plot-value plot-texts [store-plot plot-value]
    append derivation "<graph>"
    current: copy "start <plot_stmts> end"
    record-derivation current
    plot-index: 1
    plot-count: length? plots
    foreach plot plots [
        statement: "<plot>"
        if plot-index < plot-count [statement: "<plot> ; <plot_stmts>"]
        current: replace current "<plot_stmts>" statement
        record-derivation current
        current: derive-plot current plot
        plot-index: plot-index + 1
    ]
    true
]

derivation-text: func [][
    result: "LEFTMOST DERIVATION^/"
    foreach step derivation [append result rejoin [step "^/"]]
    result
]
