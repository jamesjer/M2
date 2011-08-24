-------------------
-- Package Header
-------------------
-- Copyright 2011 David W. Cook II
-- You may redistribute this file under the terms of the GNU General Public
-- License as published by the Free Software Foundation, either version 2
-- of the License, or any later version.

-- There are three tests for the Macaulay2 version number.  They may be removed after a new binary distribution of
-- Macaulay2 is available.
if version#"VERSION" <= "1.4" then needsPackage "Graphs"

newPackage select((
    "NautyGraphs",
    Version => "1.4.3",
    Date => "23. August 2011",
    Authors => {{Name => "David W. Cook II",
                 Email => "dcook@ms.uky.edu",
                 HomePage => "http://www.ms.uky.edu/~dcook"}},
    Headline => "Interface to nauty (Graphs fork)",
    Configuration => {"path" => ""},
    if version#"VERSION" > "1.4" then PackageExports => {"Graphs"},
    DebuggingMode => false,
), x -> x =!= null)

if version#"VERSION" <= "1.4" then needsPackage "Graphs"

-------------------
-- Configuration
-------------------

-- Check the ~/.Macaulay2/init-NautyGraphs.m2 file for the absolute path.
-- If it's not there, then use the M2-Programs directory.
nauty'path = (options NautyGraphs).Configuration#"path";
if nauty'path == "" then nauty'path = prefixDirectory | currentLayout#"programs";

-------------------
-- Exports
-------------------

export {
    -- Methods
    "addEdges",
    "areIsomorphic",
    "buildGraphFilter",
    "countGraphs",
    "filterGraphs",
    "generateBipartiteGraphs",
    "generateGraphs",
    "generateRandomGraphs",
    "generateRandomRegularGraphs",
    "graph6ToSparse6",
    "graphComplement",
    "graphToString",
    "isPlanar",
    "neighborhoodComplements",
    "newEdges",
    "onlyPlanar",
    "relabelBipartite",
    "relabelGraph",
    "removeEdges",
    "removeIsomorphs",
    "sparse6ToGraph6",
    "stringToEdgeIdeal",
    "stringToGraph",
    -- Options
    "Class2Degree2",
    "Class2DistinctNeighborhoods",
    "Class2MaxCommonNeighbors",
    "MaxDegree",
    "MinDegree",
    "NoNew3Cycles",
    "NoNew4Cycles",
    "NoNew5Cycles",
    "NoNewOddCycles",
    "NoNewSmallCycles",
    "Only4CycleFree",
    "OnlyBiconnected",
    "OnlyBipartite",
    "OnlyConnected",
    "OnlyIfSmaller",
    "OnlyTriangleFree",
    "RandomSeed"
}

-------------------
-- Exported Code
-------------------

-- Finds all graphs of G with an extra edge added.
addEdges = method(Options => {MaxDegree => null, NoNewOddCycles => false, NoNew3Cycles => false, NoNew4Cycles => false, NoNew5Cycles => false, NoNewSmallCycles => null})
addEdges List := List => opts -> L -> (
    cmdStr := "addedgeg -q" |
        optionZZ(opts.MaxDegree, 0, "addEdges", "MaxDegree", "D") |
        optionBoolean(opts.NoNewOddCycles, "addEdges", "NoNewOddCycles", "b") | 
        optionBoolean(opts.NoNew3Cycles, "addEdges", "NoNew3Cycles", "t") | 
        optionBoolean(opts.NoNew4Cycles, "addEdges", "NoNew4Cycles", "f") | 
        optionBoolean(opts.NoNew5Cycles, "addEdges", "NoNew5Cycles", "F") | 
        optionZZ(opts.NoNewSmallCycles, 0, "addEdges", "NoNewSmallCycles", "z");
    callNauty(cmdStr, L)
)
addEdges String := List => opts -> S -> addEdges({S}, opts)
addEdges Graph := List => opts -> G -> stringToGraph \ addEdges({G}, opts)

-- Determines if two graphs are isomorphic. 
areIsomorphic = method()
areIsomorphic (String, String) := Boolean => (G, H) -> (#callNauty("shortg -q", {G, H})) == 1
areIsomorphic (Graph, Graph) := Boolean => (G, H) -> areIsomorphic(graphToString G, graphToString H)
areIsomorphic (String, Graph) := Boolean => (G, H) -> areIsomorphic(G, graphToString H)
areIsomorphic (Graph, String) := Boolean => (G, H) -> areIsomorphic(graphToString G, H)
Graph == Graph := areIsomorphic
Graph == String := areIsomorphic
String == Graph := areIsomorphic

-- Builds a filter string for countGraphs and filterGraphs.
buildGraphFilter = method()
buildGraphFilter HashTable := String => h -> (
    validType := (str, type) -> h#?str and instance(h#str, type);
    propStart := str -> if validType(str, Boolean) and h#str then "-~" else "-";
    propBuildBoolean := (str, flag) -> if validType(str, Boolean) then ((if h#str then "-" else "-~") | flag | " ") else "";
    propBuildZZSeq := (str, flag) -> (
        if validType(str, ZZ) and h#str >= 0 then (
            propStart("Negate" | str) | flag | toString h#str | " "
        ) else if validType(str, Sequence) and #h#str == 2 then (
            if instance(h#str#0, Nothing) and instance(h#str#1, ZZ) and h#str#1 >= 0 then (
                propStart("Negate" | str) | flag | ":" | toString h#str#1 | " "
            ) else if instance(h#str#0, ZZ) and instance(h#str#1, Nothing) and h#str#0 >= 0 then (
                propStart("Negate" | str) | flag | toString h#str#0 | ":" | " "
            ) else if instance(h#str#0, ZZ) and instance(h#str#1, ZZ) and h#str#0 >=0 and h#str#1 >= h#str#0 then (
                propStart("Negate" | str) | flag | toString h#str#0 | ":" | toString h#str#1 | " "
            ) else ""
        ) else ""
    );

    concatenate {propBuildZZSeq("NumVertices", "n"),         propBuildZZSeq("NumEdges", "e"),
                 propBuildZZSeq("MinDegree", "d"),           propBuildZZSeq("MaxDegree", "D"),
                 propBuildBoolean("Regular", "r"),           propBuildBoolean("Bipartite", "b"),
                 propBuildZZSeq("Radius", "z"),              propBuildZZSeq("Diameter", "Z"),
                 propBuildZZSeq("Girth", "g"),               propBuildZZSeq("NumCycles", "Y"),
                 propBuildZZSeq("NumTriangles", "T"),        propBuildBoolean("Eulerian", "E"),
                 propBuildZZSeq("GroupSize", "a"),           propBuildZZSeq("Orbits", "o"),
                 propBuildZZSeq("FixedPoints", "F"),         propBuildBoolean("VertexTransitive", "t"),
                 propBuildZZSeq("Connectivity", "c"),
                 propBuildZZSeq("MinCommonNbrsAdj", "i"),    propBuildZZSeq("MaxCommonNbrsAdj", "I"),
                 propBuildZZSeq("MinCommonNbrsNonAdj", "j"), propBuildZZSeq("MaxCommonNbrsNonAdj", "J")
                }
)
buildGraphFilter List := String => L -> buildGraphFilter hashTable L

-- Count the graphs with certain properties.
countGraphs = method()
countGraphs (List, String) := ZZ => (L, filter) -> (
    if #L == 0 or #filter == 0 then return #L;
    r := callNauty("countg -q " | filter, L);
    if not instance(r, List) or #r == 0 then return;
    p := regex("g", first r);
    if not instance(p, Nothing) then value substring((0, first first regex("g", first r)), first r) 
    else error("countGraphs: One or more of the input graphs was formatted incorrectly.")
)
countGraphs (List, HashTable) := ZZ => (L, fh) -> countGraphs(L, buildGraphFilter fh)
countGraphs (List, List) := ZZ => (L, fl) -> countGraphs(L, buildGraphFilter hashTable fl)

-- Filter a list of graphs for certain properties.
filterGraphs = method()
filterGraphs (List, String) := List => (L, filter) -> (
    if #L == 0 or #filter == 0 then return L;
    -- nauty outputs useful information to the stderr and (to us) junk on stdout
    r := callNauty("pickg -qV " | filter, L, ReadError => true);
    -- In nauty 2.4r2, the index is the first number.
    for l in r list ( s := select("[[:digit:]]+", l); if #s == 0 then continue else L_(-1 + value first s) )
)
filterGraphs (List, HashTable) := List => (L, fh) -> filterGraphs(L, buildGraphFilter fh)
filterGraphs (List, List) := List => (L, fl) -> filterGraphs(L, buildGraphFilter hashTable fl)

-- Generates all bipartite graphs of a given type.
generateBipartiteGraphs = method(Options => {OnlyConnected => false, Class2DistinctNeighborhoods => false, Class2Degree2 => false, Class2MaxCommonNeighbors => null, MaxDegree => null, MinDegree => null})
generateBipartiteGraphs (ZZ, ZZ, ZZ, ZZ) := List => opts -> (n, m, le, ue) -> (
    if n < 1 then error("generateBipartiteGraphs: nauty does not like graphs with non-positive numbers of vertices.");
    if m == 0 then return generateBipartiteGraphs(n, n, le, ue, opts);
    if m < 0 then error("generateBipartiteGraphs: The first class cannot have a negative number of vertices.");
    if m > n then error("generateBipartiteGraphs: The first class has too many vertices.");
    if le > ue or le > m*(n-m) or ue < 0 then return {};

    cmdStr := "genbg -q" | 
        optionBoolean(opts.OnlyConnected, "generateBipartiteGraphs", "OnlyConnected", "c") | 
        optionBoolean(opts.Class2DistinctNeighborhoods, "generateBipartiteGraphs", "Class2DistinctNeighborhoods", "z") | 
        optionBoolean(opts.Class2Degree2, "generateBipartiteGraphs", "Class2Degree2", "F") | 
        optionZZ(opts.Class2MaxCommonNeighbors, 0, "generateBipartiteGraphs", "Class2MaxCommonNeighbors", "Z") | 
        optionZZ(opts.MinDegree, 0, "generateBipartiteGraphs", "MinDegree", "d") | 
        optionZZ(opts.MaxDegree, 0, "generateBipartiteGraphs", "MaxDegree", "D") | 
        (" " | toString m | " " | toString(n-m) | " " | toString le | ":" | toString ue);

    callNauty(cmdStr, {})
)
generateBipartiteGraphs (ZZ, ZZ, ZZ) := List => opts -> (n, m, e) -> generateBipartiteGraphs(n, m, e, e, opts)
generateBipartiteGraphs (ZZ, ZZ) := List => opts -> (n, m) -> generateBipartiteGraphs(n, m, 0, m * (n-m), opts)
generateBipartiteGraphs ZZ := List => opts -> n -> unique flatten apply(toList (1..n), i -> generateBipartiteGraphs(n, i, opts))

-- Generates all graphs of a given type.
generateGraphs = method(Options => {OnlyConnected => false, OnlyBiconnected => false, OnlyTriangleFree => false, Only4CycleFree => false, OnlyBipartite => false, MinDegree => null, MaxDegree => null})
generateGraphs (ZZ, ZZ, ZZ) := List => opts -> (n, le, ue) -> (
    if n < 1 then error("generateGraphs: nauty does not like graphs with non-positive numbers of vertices.");
    if le > ue or le > binomial(n,2) or ue < 0 then return {};
    le = max(le, 0);

    cmdStr := "geng -q" |
        optionBoolean(opts.OnlyConnected, "generateGraphs", "OnlyConnected", "c") |
        optionBoolean(opts.OnlyBiconnected, "generateGraphs", "OnlyBiconnected", "C") |
        optionBoolean(opts.OnlyTriangleFree, "generateGraphs", "OnlyTriangleFree", "t") |
        optionBoolean(opts.Only4CycleFree, "generateGraphs", "Only4CycleFree", "f") |
        optionBoolean(opts.OnlyBipartite, "generateGraphs", "OnlyBipartite", "b") |
        optionZZ(opts.MinDegree, 0, "generateBipartiteGraphs", "MinDegree", "d") | 
        optionZZ(opts.MaxDegree, 0, "generateBipartiteGraphs", "MaxDegree", "D") | 
        (" " | toString n | " " | toString le | ":" | toString ue);
    
    callNauty(cmdStr, {})
)
generateGraphs (ZZ, ZZ) := List => opts -> (n, e) -> generateGraphs(n, e, e, opts)
generateGraphs ZZ := List => opts -> n -> generateGraphs(n, 0, binomial(n, 2), opts)

-- Generate random graphs with given properties.
generateRandomGraphs = method(Options => {RandomSeed => null})
generateRandomGraphs (ZZ, ZZ, ZZ) := List => opts -> (n, num, p) -> (
    if n < 1 then error("generateRandomGraphs: nauty does not like graphs with non-positive numbers of vertices.");
    if p < 1 then error("generateRandomGraphs: Probability must be positive.");
    if not instance(opts.RandomSeed, Nothing) and not instance(opts.RandomSeed, ZZ) then error("generateRandomGraphs: Option [RandomSeed] is not a valid type, i.e., ZZ or Nothing.");
    if p > 100000000 then p = 100000000; --silently bound it
    if num < 1 then return {};
    rndSeed := if instance(opts.RandomSeed, ZZ) then " -S" | toString(opts.RandomSeed % 2^30) else "";
    callNauty("genrang -qg -P" | toString p | " "  | toString n | " " | toString num | rndSeed, {})
)
generateRandomGraphs (ZZ, ZZ, QQ) := List => opts -> (n, num, p) -> (
    if n < 1 then error("generateRandomGraphs: nauty does not like graphs with non-positive numbers of vertices.");
    if num < 1 then return {};
    if p <= 0 or p > 1 then error("generateRandomGraphs: Probability must be between 0 and 1.");
    if not instance(opts.RandomSeed, Nothing) and not instance(opts.RandomSeed, ZZ) then error("generateRandomGraphs: Option [RandomSeed] is not a valid type, i.e., ZZ or Nothing.");
    rndSeed := if instance(opts.RandomSeed, ZZ) then " -S" | toString(opts.RandomSeed % 2^30) else "";
    -- limit the precision to 1e-8
    q := round(100000000 * p) / 100000000;
    callNauty("genrang -qg -P" | toString q | " "  | toString n | " " | toString num | rndSeed, {})
)
generateRandomGraphs (ZZ, ZZ, RR) := List => opts -> (n, num, p) -> generateRandomGraphs(n, num, promote(p, QQ), opts)
generateRandomGraphs (ZZ, ZZ) := List => opts -> (n, num) -> (
    if n < 1 then error("generateRandomGraphs: nauty does not like graphs with non-positive numbers of vertices.");
    if not instance(opts.RandomSeed, Nothing) and not instance(opts.RandomSeed, ZZ) then error("generateRandomGraphs: Option [RandomSeed] is not a valid type, i.e., ZZ or Nothing.");
    if num < 1 then return {};
    rndSeed := if instance(opts.RandomSeed, ZZ) then " -S" | toString(opts.RandomSeed % 2^30) else "";
    callNauty("genrang -qg " | toString n | " " | toString num | rndSeed, {})
)

-- Generate random regular graphs in the Ring with given properties.
generateRandomRegularGraphs = method(Options => {RandomSeed => null})
generateRandomRegularGraphs (ZZ, ZZ, ZZ) := List => opts -> (n, num, reg) -> (
    if n < 1 then error("generateRandomRegularGraphs: nauty does not like graphs with non-positive numbers of vertices.");
    if not instance(opts.RandomSeed, Nothing) and not instance(opts.RandomSeed, ZZ) then error("generateRandomGraphs: Option [RandomSeed] is not a valid type, i.e., ZZ or Nothing.");
    if num < 1 then return {};
    if reg < 1 or reg >= n then error("generateRandomRegularGraphs: Regularity must be positive but less than the number of vertices.");
    if odd n and odd reg then error("generateRandomRegularGraphs: There are no graphs with odd regularity on an odd number of vertices.");
    rndSeed := if instance(opts.RandomSeed, ZZ) then " -S" | toString(opts.RandomSeed % 2^30) else "";
    callNauty("genrang -qg -r" | toString reg | " " | toString n | " " | toString num | rndSeed, {})
)

-- Converts a Graph6 string to a Sparse6 string.
graph6ToSparse6 = method()
graph6ToSparse6 String := String => g6 -> first callNauty("copyg -qs", {g6})

-- Complements a graph.
graphComplement = method(Options => {OnlyIfSmaller => false})
graphComplement List := List => opts -> L -> (
    cmdStr := "complg -q" | optionBoolean(opts.OnlyIfSmaller, "graphComplement", "OnlyIfSmaller", "r");
    callNauty(cmdStr, L)
)
graphComplement String := String => opts -> S -> first graphComplement({S}, opts)
graphComplement Graph := Graph => opts -> G -> stringToGraph first graphComplement({G}, opts)

-- Converts a graph to a string in Graph6 format.
graphToString = method()
graphToString (List, ZZ) := String => (E, n) -> (
    if n < 1 then error("graphToString: nauty does not like graphs with non-positive numbers of vertices.");
    if n > 68719476735 then error("graphToString: nauty does not like too many vertices (more than 68719476735).");
    if any(E, e -> #e != 2) or any(E, e -> first e == last e) or max(flatten E) >= n then error("graphToString: Edges are malformed.");
    N := take(reverse apply(6, i -> (n // 2^(6*i)) % 2^6), if n < 63 then -1 else if n < 258047 then -3 else -6);

    B := new MutableList from toList(6*ceiling(binomial(n,2)/6):0);
    -- the edges must be in {min, max} order, so sort them
    for e in sort \ E do B#(binomial(last e, 2) + first e) = 1;
    ascii apply(N | apply(pack(6, toList B), b -> fold((i,j) -> i*2+j, b)), l -> l + 63)
)
graphToString MonomialIdeal := String => I -> graphToString(indices \ first entries generators I, #gens ring I)
graphToString Ideal := String => I -> graphToString monomialIdeal I
graphToString Graph := String => G -> (
    V := vertices G;
    idx := hashTable apply(#V, i-> V_i => i);
    E := apply(toList \ edges G, e -> {idx#(e_0), idx#(e_1)});
    graphToString(E, #V)
);
graphToString String := String => S -> S

-- Tests the planarity of a graph
isPlanar = method()
isPlanar String := Boolean => G -> (#callNauty("planarg -q", {G})) != 0
isPlanar Graph := Boolean => G -> isPlanar(graphToString G)

-- For each vertex, switch the edges between its neighborhood and its neighborhood's complement.
neighborhoodComplements = method()
neighborhoodComplements List := List => L -> callNauty("NRswitchg -q", L)
neighborhoodComplements String := List => S -> neighborhoodComplements {S}
neighborhoodComplements Graph := List => G -> stringToGraph \ neighborhoodComplements {G}

-- For each disjoint pair of edges (a,b), (c,d), replace the edges with 
-- (a,e), (e,b), (c,f), (f,d), and add the edge (e,f), where {e,f} are
-- new vertices.
newEdges = method()
newEdges List := List => L -> callNauty("newedgeg -q", L)
newEdges String := List => S -> newEdges {S}
newEdges Graph := List => G -> stringToGraph \ newEdges {G}

-- Removes non-planar graphs from a list of graphs
onlyPlanar = method()
onlyPlanar (List, Boolean) := List => (L, non) -> (
    cmdStr := "planarg -q " | if non then "-v" else "";
    callNauty(cmdStr, L)
)
onlyPlanar List := List => L -> onlyPlanar(L, false)

-- Reorders a bipartite graph so all vertices of each color are continguous.
relabelBipartite = method()
relabelBipartite List := List => L -> (
    r := callNauty("biplabg -q", L);
    if #r == #L then r else error("relabelBipartite: One of the graphs is not a bipartite graph.")
)
relabelBipartite String := String => S -> first relabelBipartite {S}
relabelBipartite Graph := Graph => G -> stringToGraph first relabelBipartite {G}

-- Relabels a graph using a canonical labelling.
relabelGraph = method()
relabelGraph (List, ZZ, ZZ) := List => (L, i, a) -> (
    if i > 15 or i < 0 then error("relabelGraph: The invariant selected is invalid.");
    if a < 0 then error("relabelGraph: The invariant argument must be nonnegative.");
    callNauty("labelg -qg -i" | toString i | " -K" | toString a, L)
)
relabelGraph (String, ZZ, ZZ) := String => (S, i, a) -> first relabelGraph({S}, i, a)
relabelGraph (Graph, ZZ, ZZ) := Graph => (G, i, a) -> stringToGraph first relabelGraph({G}, i, a)
relabelGraph (List, ZZ) := String => (L, i) -> relabelGraph(L, i, 3)
relabelGraph (String, ZZ) := String => (S, i) -> first relabelGraph({S}, i, 3)
relabelGraph (Graph, ZZ) := Graph => (G, i) -> stringToGraph first relabelGraph({G}, i, 3)
relabelGraph List := String => L -> relabelGraph(L, 0, 3)
relabelGraph String := String => S -> first relabelGraph({S}, 0, 3)
relabelGraph Graph := Graph => G -> stringToGraph first relabelGraph({G}, 0, 3)
        
-- Finds all graphs defined by G with one edge removed.
removeEdges = method(Options => {MinDegree => null})
removeEdges List := List => opts -> L -> (
    cmdStr := "deledgeg -q" | optionZZ(opts.MinDegree, 0, "removeEdges", "MinDegree", "d");
    callNauty(cmdStr, L)
)
removeEdges String := List => opts -> S -> removeEdges({S}, opts)
removeEdges Graph := List => opts -> G -> stringToGraph \ removeEdges({G}, opts)

-- Removes all isomorphs from a list of graphs. 
removeIsomorphs = method()
removeIsomorphs List := List => L -> (
    if #L == 0 then return {};
    -- nauty outputs useful information to the stderr and (to us) junk on stdout
    r := callNauty("shortg -qv", L, ReadError => true);
    -- for each line, check if it has a colon, if so, take the first graph
    for l in r list ( 
        s := separate(":", l);
        if #s < 2 then continue else ( 
            t := select("[[:digit:]]+", s_1);
            if #t == 0 then continue else L_(-1 + value first t)
        )
    )
)

-- Converts a Sparse6 string to a Graph6 string.
sparse6ToGraph6 = method()
sparse6ToGraph6 String := String => (s6) -> (
    r := callNauty("copyg -qg", {s6});
    if #r != 0 then first r else error("sparse6ToGraph6: The graph format is incorrect.")
)

-- Converts a graph given by a string in either Sparse6 or Graph6 format to an edge ideal in the given ring.
stringToEdgeIdeal = method()
stringToEdgeIdeal (String, PolynomialRing) := MonomialIdeal => (str, R) -> (
    L := stringToList str;
    if first L != #gens R then error("stringToEdgeIdeal: Wrong number of variables in the ring.");
    E := last L;
    monomialIdeal if #E == 0 then 0_R else apply(E, e -> R_(e_0) * R_(e_1))
)

-- Converts a string to a graph object
stringToGraph = method()
stringToGraph String := Graph => str -> (
    L := stringToList str;
    V := toList(0..(first L - 1));
    V' := unique flatten last L;
    if #V' == #V then graph last L else graph(last L, Singletons => select(V, v -> not member(v, V')))
);

-------------------
-- Local-Only Code
-------------------

-- Sends a command and retrieves the results into a list of lines.
-- If ReadError is set to true and the command is successfully executed,
-- then the data from stderr is returned (filterGraphs and removeIsomorphs
-- use this).
protect ReadError;
callNauty = method(Options => {ReadError => false})
callNauty (String, List) := List => opts -> (cmdStr, dataList) -> (
    infn := temporaryFileName();
    erfn := temporaryFileName();
    -- output the data to a file
    o := openOut infn;
    scan(graphToString \ dataList, d -> o << d << endl);
    close o;
    -- try to harvest the lines
    r := lines try get openIn ("!" | nauty'path | cmdStr | " <" | infn | " 2>" | erfn)
    else (
        -- nauty errored, harvest the error
        e := last separate(":", first lines get openIn erfn);
        removeFile infn;
        removeFile erfn;
        -- special cases 
        if e == " not found" then error("callNauty: nauty could not be found on the path [" | nauty'path | "].");
        if e == "#q -V] [--keys] [-constraints -v] [ifile [ofile]]" then e = "invalid filter";
	    error("callNauty: nauty terminated with the error [", e, "].");
    );
    removeFile infn;
    -- If the method wants it, then read the stderr data instead.
    if opts.ReadError then (
        r = lines try get openIn erfn else (
            removeFile erfn;
            error("callNauty: nauty ran successfully, but no data was written to stderr as expected.  Report this to the package maintainer.");
        );
    );
    removeFile erfn;
    r
)

-- Processes an option which should be a Boolean.
-- Throws an appropriate error if the type is bad, otherwise it returns the flag.
optionBoolean = (b, m, o, f) -> (
    if instance(b, Nothing) then ""
    else if not instance(b, Boolean) then error(m | ": Option [" | o | "] is not a valid type, i.e., Boolean or Nothing.")
    else if b then " -" | f 
    else ""
)

-- Processes an option which should be an integer (ZZ).
-- Throws an approprate error if the type is bad or the bound is bad, otherwise it returns the flag.
optionZZ = (i, b, m, o, f) -> (
    if instance(i, Nothing) then ""
    else if not instance(i, ZZ) then error(m | ": Option [" | o | "] is not a valid type, i.e., ZZ or Nothing.")
    else if i < b then error(m | ": Option [" | o | "] is too small (minimum is " | toString b | ").")
    else " -" | f | toString i
)

-- Converts a graph given by a string in either Sparse6 or Graph6 format to a list
stringToList = method()
stringToList String := List => str -> (
    -- basic parse
    if #str == 0 then return;
    sparse := str_0 == ":";
    A := apply(ascii str, l -> l - 63);
    if sparse then A = drop(A, 1);
    if min A < 0 or max A > 63 then error("stringToList: Not a Sparse6/Graph6 string.");

    -- get number of vertices
    p := 0;
    n := if A_0 < 63 then (
             p = 1;
             A_0
         ) else if A_1 < 63 then ( 
             if #A < 4 then error("stringToList: Not a Sparse6/Graph6 string.");
             p = 4;
             fold((i,j) -> i*2^6+j, take(A, {1,3}))
         ) else (
             if #A < 8 then error("stringToList: Not a Sparse6/Graph6 string.");
             p = 8;
             fold((i,j) -> i*2^6+j, take(A, {2,7}))
         );

    bits := flatten apply(drop(A, p), n -> ( n = n*2; reverse for i from 1 to 6 list (n=n//2)%2 ));
    c := 0;

    {n, if sparse then (
        -- Sparse6 format
        k := ceiling(log(n) / log(2));
        v := 0;
        xi := 0;
        while c + k < #bits list (
            if bits_c == 1 then v = v + 1;
            xi = fold((i,j) -> 2*i+j, take(bits, {c+1,c+k})); 
            c = c + k + 1;
            if xi > v then ( v = xi; continue ) else {xi, v}
        )
    ) else ( 
        -- Graph6 format
        if #A != p + ceiling(n*(n-1)/12) then error("stringToList: Not a Graph6 string.");
        c = -1;
        flatten for i from 1 to n - 1 list for j from 0 to i - 1 list ( c = c + 1; if bits_c == 1 then {i, j} else continue)
    )}
)

-------------------
-- Documentation
-------------------
beginDocumentation()

doc ///
    Key
        NautyGraphs
    Headline
        Interface to nauty (Graphs fork)
    Description
        Text
            This package provides an interface from Macaulay2 to many of the functions provided in
            the software nauty by Brendan D. McKay, available at @HREF "http://cs.anu.edu.au/~bdm/nauty/"@.
            The nauty package provides very efficient methods for determining whether
            given graphs are isomorphic, generating all graphs with particular properties,
            generating random graphs, and more.
            
            Most methods can handle graphs in either the Macaulay2 @TO "Graph"@ type as provided by
            the @TO "Graphs"@ package or as Graph6 and Sparse6 strings as used by nauty.
            The purpose of this is that graphs stored as strings are greatly more efficient than
            graphs stored as instances of the class @TO "Graph"@.  
            (See @TO "Comparison of Graph6 and Sparse6 formats"@.)

            It is recommended to work with graphs represented as strings while using nauty-provided
            methods and then converting the graphs to instances of the class @TO "Graph"@ for further work.

            The theoretical underpinnings of nauty are in the paper:
            B. D. McKay, "Practical graph isomorphism," Congr. Numer. 30 (1981), 45--87.
    SeeAlso
        "Comparison of Graph6 and Sparse6 formats"
        "Example: Checking for isomorphic graphs"
        "Example: Generating and filtering graphs"
///


doc ///
    Key
        addEdges
        (addEdges, List)
        (addEdges, String)
        (addEdges, Graph)
        [addEdges, MaxDegree]
        [addEdges, NoNew3Cycles]
        [addEdges, NoNew4Cycles]
        [addEdges, NoNew5Cycles]
        [addEdges, NoNewOddCycles]
        [addEdges, NoNewSmallCycles]
    Headline
        creates a list of graphs obtained by adding one new edge to the given graph in all possible ways
    Usage
        Ll = addEdges L
        Lg = addEdges G
        Ls = addEdges S
    Inputs
        L:List
            containing graphs in various formats
        S:String
            which describes a graph in Graph6 or Sparse6 format
        G:Graph
        MaxDegree=>ZZ
            the maximum degree allowable for any vertex in the output graphs
        NoNew3Cycles=>Boolean
            whether graphs with new 3-cycles are allowed
        NoNew4Cycles=>Boolean
            whether graphs with new 4-cycles are allowed
        NoNew5Cycles=>Boolean
            whether graphs with new 5-cycles are allowed
        NoNewOddCycles=>Boolean
            whether graphs with new odd-cycles are allowed
        NoNewSmallCycles=>ZZ
            an upper bound on cycles which are not allowed
    Outputs
        Ll:List
            the list of graphs obtained from the graphs in $L$ in Graph6 format
        Lg:List
            the list of graphs obtained from $G$
        Ls:List
            the list of strings (in Graph6 format) obtained from $S$
    Description
        Text
            Simply creates a list, in the same format as the input, of all possible graphs
            obtained by adding one new edge to the input graph.
        Example
            G = graph {{1,2},{2,3},{3,4},{4,5},{1,5}};
            addEdges G
        Text
            If the List input format is used, then one should use care as
            the list may contain isomorphic pairs.
    SeeAlso
        removeEdges
///

doc ///
    Key
        areIsomorphic
        (areIsomorphic, String, String)
        (areIsomorphic, Graph, Graph)
        (areIsomorphic, String, Graph)
        (areIsomorphic, Graph, String)
        (symbol ==, Graph, Graph)
        (symbol ==, Graph, String)
        (symbol ==, String, Graph)
    Headline
        determines whether two graphs are isomorphic
    Usage
        b = areIsomorphic(G, H)
        G == H
        b = areIsomorphic(S, T)
        b = areIsomorphic(S, H)
        S == H
        b = areIsomorphic(G, T)
        G == T
    Inputs
        G:Graph
        H:Graph
        S:String
        T:String
    Outputs
        b:Boolean
            whether the two graphs are isomorphic
    Description
        Text
            A very efficient method for determing whether two graphs (of the same format) are isomorphic.
        Example
            G = graph {{1,2},{2,3},{3,4},{4,5},{1,5}};
            H = graph {{1,3},{3,5},{5,2},{2,4},{4,1}};
            I = graph {{1,2},{1,3},{1,4},{1,5},{2,3},{2,4},{2,5},{3,4},{3,5},{4,5}};
            areIsomorphic(G, H)
            G == H
            areIsomorphic(G, I)
            G == "Dhc"
            I == "Dhc"

    SeeAlso
        "Example: Checking for isomorphic graphs"
        removeIsomorphs
///

doc ///
    Key
        buildGraphFilter
        (buildGraphFilter, HashTable)
        (buildGraphFilter, List)
    Headline
        creates the appropriate filter string for use with filterGraphs and countGraphs
    Usage
        s = buildGraphFilter h
        s = buildGraphFilter l
    Inputs
        h:HashTable
            which describes the properties desired in filtering
        l:List
            which describes the properties desired in filtering
    Outputs
        s:String
            which can be used with @TO "filterGraphs"@ and @TO "countGraphs"@
    Description
        Text
            The @TO "filterGraphs"@ and @TO "countGraphs"@ methods both can use a tremendous number of constraints
            which are described by a rather tersely encoded string.  This method builds that string given information
            in the @TO "HashTable"@ $h$ or the @TO "List"@ $l$.  Any keys which do not exist are simply ignored and 
            any values which are not valid (e.g., exactly $-3$ vertices) are also ignored.
            
            The values can either be @TO "Boolean"@ or in @TO "ZZ"@.  @TO "Boolean"@ values are treated exactly
            as expected.  Numerical values are more complicated; we use an example to illustrate how numerical values
            can be used, but note that this usage works for all numerically valued keys.
 
            The key @TT "NumEdges"@ restricts to a specific number of edges in the graph.  If the value is
            the integer $n$, then only graphs with @EM "exactly"@ $n$ edges are returned.
        Example
            L = {graph {{1,2}}, graph {{1,2},{2,3}}, graph {{1,2},{2,3},{3,4}}, graph {{1,2},{2,3},{3,4},{4,5}}};
            s = buildGraphFilter {"NumEdges" => 3};
            filterGraphs(L, s)
        Text
            If the value is the @TO "Sequence"@ $(m,n)$, then all graphs with at least $m$ and at most $n$ edges are returned.
        Example
            s = buildGraphFilter {"NumEdges" => (2,3)};
            filterGraphs(L, s)
        Text
            If the value is the @TO "Sequence"@ $(,n)$, then all graphs with at most $n$ edges are returned.
        Example
            s = buildGraphFilter {"NumEdges" => (,3)};
            filterGraphs(L, s)
        Text
            If the value is the @TO "Sequence"@ $(m,)$, then all graphs with at least $m$ edges are returned.
        Example
            s = buildGraphFilter {"NumEdges" => (2,)};
            filterGraphs(L, s)
        Text
            Moreover, the associated key @TT "NegateNumEdges"@, if true, causes the @EM "opposite"@ to occur.
        Example
            s = buildGraphFilter {"NumEdges" => (2,), "NegateNumEdges" => true};
            filterGraphs(L, s)
        Text
            The following are the boolean options: "Regular", "Bipartite", "Eulerian", "VertexTransitive".

            The following are the numerical options (recall all have the associate "Negate" option): "NumVertices", "NumEdges",
            "MinDegree", "MaxDegree", "Radius", "Diameter", "Girth", "NumCycles", "NumTriangles", "GroupSize", "Orbits",
            "FixedPoints", "Connectivity", "MinCommonNbrsAdj", "MaxCommonNbrsAdj", "MinCommonNbrsNonAdj", "MaxCommonNbrsNonAdj".
    Caveat
            @TT "Connectivity"@ only works for the values $0, 1, 2$ and uses the following definition of $k$-connectivity.
            A graph is $k$-connected if $k$ is the minimum size of a set of vertices whose complement is not connected.

            Thus, in order to filter for connected graphs, one must use @TT "{\"Connectivity\" => 0, \"NegateConnectivity\" => true}"@.

            @TT "NumCycles"@ can only be used with graphs on at most $n$ vertices, where $n$ is the number of bits for which
            nauty was compiled, typically $32$ or $64$.
    SeeAlso
        countGraphs
        "Example: Generating and filtering graphs"
        filterGraphs
///

doc ///
    Key
        "Comparison of Graph6 and Sparse6 formats"
    Description
        Text
            The program nauty uses two string-based formats for storing graphs:  Graph6 and Sparse6 format.
            Each format has benefits and drawbacks.  

            In particular, the length of a Graph6 string representation of a graph depends only on the number of vertices.
            However, this also means that graphs with few edges take as much space as graphs with many edges.
            On the other hand, Sparse6 is a variable length format which can use dramatically less space for
            sparse graphs but can have a much larger storage size for dense graphs.

            Consider the 26-cycle, a rather sparse graph.  Notice how Sparse6 format takes half the space
            of the Graph6 format.
        Example
            C26 = graph append(apply(25, i -> {i, i+1}), {0, 25});
            g6 = graphToString C26; #g6
            s6 = graph6ToSparse6 g6; #s6
        Text
            However, the complete graph, which is as dense as possible, on 26 vertices is the opposite: 
            the Sparse6 format takes nearly six times the space of the Graph6 format.
        Example
            K26 = graph flatten for i from 0 to 25 list for j from i+1 to 25 list {i,j};
            g6 = graphToString K26; #g6
            s6 = graph6ToSparse6 g6; #s6
    SeeAlso
        graph6ToSparse6
        graphToString
        sparse6ToGraph6
        stringToGraph
///

doc ///
    Key
        countGraphs
        (countGraphs, List, String)
        (countGraphs, List, HashTable)
        (countGraphs, List, List)
    Headline
        counts the number of graphs in the list with given properties
    Usage
        n = countGraphs(L, s)
        n = countGraphs(L, h)
        n = countGraphs(L, l)
    Inputs
        L:List
            containing graphs (mixed formats are allowed)
        s:String
            a filter, as generated by @TO "buildGraphFilter"@
        h:HashTable
            a filter, as used by @TO "buildGraphFilter"@
        l:List
            a filter, as used by @TO "buildGraphFilter"@
    Outputs
        n:ZZ
            the number of graphs in $L$ satisfying the filter
    Description
        Text
            Counts the number of graphs in a list that satisfy certain restraints as given in
            the filter (see @TO "buildGraphFilter"@).  Notice that the input list can be graphs
            represented as instances of the class @TO "Graph"@ or in a nauty-based @TO "String"@ format.
        Text
            For example, we can count the number of connected graphs on five vertices.
        Example
            L = generateGraphs 5;
            countGraphs(L, {"Connectivity" => 0, "NegateConnectivity" => true})
    SeeAlso
        buildGraphFilter
        filterGraphs
///

doc ///
    Key
        "Example: Checking for isomorphic graphs"
    Description
        Text
            The main use of nauty is to determine if two graphs are isomorphic.  We can
            demonstrate it for two given graphs with the method @TO "areIsomorphic"@.  
        Example
            G = graph {{1,2},{2,3},{3,4},{4,5},{1,5}};
            H = graph {{1,3},{3,5},{5,2},{2,4},{4,1}};
            areIsomorphic(G, H)
        Text
            Further, a list of graphs can be reduced to only graphs that are non-isomorphic
            with the method @TO "removeIsomorphs"@.  Here we create a list of 120 different
            labellings of the 5-cycle and use nauty to verify they are indeed all
            the same.
        Example
            L = graphToString \ apply(permutations 5, P -> graph apply(5, i -> {P_i, P_((i+1)%5)}));
            N = removeIsomorphs L
            stringToGraph first N
    SeeAlso
        areIsomorphic
        removeIsomorphs
///

doc ///
    Key
        "Example: Generating and filtering graphs"
    Description
        Text
            The method @TO "generateGraphs"@ can generate all graphs with a given property.
            For example, we can verify the number of graphs on a given number of vertices.
            Compare these results to the Online Encyclopedia of Integer Sequences (@HREF "http://oeis.org/"@),
            where the sequence name is also its OEIS identifier.
        Example
            A000088 = apply(1..9, n -> #generateGraphs n)
            B = apply(1..12, n -> generateGraphs(n, OnlyBipartite => true));
        Text
            Further, we can use @TO "filterGraphs"@ to refine the set of generate graphs
            for deeper properties.

            Here we filter for forests, then for trees only,
        Example
            forestsOnly = buildGraphFilter {"NumCycles" => 0};
            A005195 = apply(B, graphs -> #filterGraphs(graphs, forestsOnly))
            treesOnly = buildGraphFilter {"NumCycles" => 0, "Connectivity" => 0, "NegateConnectivity" => true};
            A000055 = apply(B, graphs -> #filterGraphs(graphs, treesOnly))
        Text
            Moreover, we can generate random graphs using the @TO "generateRandomGraphs"@ method.  Here
            we verify a result of Erdos and R\'enyi (see @HREF "http://www.ams.org/mathscinet-getitem?mr=120167"@),
            which says that a random graph on $n$ vertices with edge probability $(1+\epsilon)$log$(n)/n$ is almost
            always connected while a graph with edge probability $(1-\epsilon)$log$(n)/n$ is almost never connected,
            at least as $n$ tends to infinity.
        Example
            connected = buildGraphFilter {"Connectivity" => 0, "NegateConnectivity" => true};
            prob = n -> log(n)/n;
            apply(2..30, n -> #filterGraphs(generateRandomGraphs(n, 100, 2*(prob n)), connected))
            apply(2..30, n -> #filterGraphs(generateRandomGraphs(n, 100, (prob n)/2), connected))
    SeeAlso
        buildGraphFilter
        filterGraphs
        generateGraphs
        generateRandomGraphs
///
            

doc ///
    Key
        filterGraphs
        (filterGraphs, List, String)
        (filterGraphs, List, HashTable)
        (filterGraphs, List, List)
    Headline
        filters (i.e., selects) graphs in a list for given properties
    Usage
        F = filterGraphs(L, s)
        F = filterGraphs(L, h)
        F = filterGraphs(L, l)
    Inputs
        L:List
            containing graphs (mixed formats are allowed)
        s:String
            a filter, as generated by @TO "buildGraphFilter"@
        h:HashTable
            a filter, as used by @TO "buildGraphFilter"@
        l:List
            a filter, as used by @TO "buildGraphFilter"@
    Outputs
        F:List
            the graphs in $L$ satisfying the filter
    Description
        Text
            Filters the graphs in a list which satisfy certain restraints as given in
            the filter (see @TO "buildGraphFilter"@).  Notice that the input list can be graphs
            represented as instances of the class @TO "Graph"@ or in a nauty-based @TO "String"@ format.
        Text
            For example, we can filter for the connected graphs on five vertices.
        Example
            L = generateGraphs 5;
            filterGraphs(L, {"Connectivity" => 0, "NegateConnectivity" => true})
    SeeAlso
        buildGraphFilter
        countGraphs
        "Example: Generating and filtering graphs"
///

doc ///
    Key
        generateBipartiteGraphs
        (generateBipartiteGraphs, ZZ)
        (generateBipartiteGraphs, ZZ, ZZ)
        (generateBipartiteGraphs, ZZ, ZZ, ZZ)
        (generateBipartiteGraphs, ZZ, ZZ, ZZ, ZZ)
        [generateBipartiteGraphs, Class2Degree2]
        [generateBipartiteGraphs, Class2DistinctNeighborhoods]
        [generateBipartiteGraphs, Class2MaxCommonNeighbors]
        [generateBipartiteGraphs, MaxDegree]
        [generateBipartiteGraphs, MinDegree]
        [generateBipartiteGraphs, OnlyConnected]
    Headline
        generates the bipartite graphs with a given bipartition
    Usage
        G = generateBipartiteGraphs n
        G = generateBipartiteGraphs(n, m)
        G = generateBipartiteGraphs(n, m, e)
        G = generateBipartiteGraphs(n, m, le, ue)
    Inputs
        n:ZZ
            the number of vertices of the graphs, must be positive (see caveat)
        m:ZZ
            the number of vertices in the first class of the bipartition
        e:ZZ
            the number of edges in the graphs
        le:ZZ
            a lower bound on the number of edges in the graphs
        ue:ZZ 
            an upper bound on the number of edges in the graphs
        Class2Degree2=>Boolean
            whether the vertices in the second class must have at least two neighbors of degree at least 2
        Class2DistinctNeighborhoods=>Boolean 
            whether all vertices in the second class must have distinct neighborhoods
        Class2MaxCommonNeighbors=>ZZ
            an upper bound on the number of common neighbors of vertices in the second class
        MaxDegree=>ZZ
            an upper bound on the degrees of the vertices
        MinDegree=>ZZ
            a lower bound on the degrees of the vertices
        OnlyConnected=>Boolean
            whether to only allow connected graphs
    Outputs
        G:List
            the bipartite graphs satisfying the input conditions
    Description
        Text
            This method generates all bipartite graphs on $n$ vertices.  
            The size of the bipartition is specified by giving the size of
            one class; the other class is determined automatically from the
            number of vertices.
        Text
            If only one integer argument is given, then the method generates
            all bipartite graphs on that number of vertices with first class
            of sizes $0$ to $n$.
    Caveat
        The number of vertices $n$ must be positive as nauty cannot handle
        graphs with zero vertices.
    SeeAlso
        generateGraphs
///

doc ///
    Key
        generateGraphs
        (generateGraphs, ZZ)
        (generateGraphs, ZZ, ZZ)
        (generateGraphs, ZZ, ZZ, ZZ)
        [generateGraphs, MaxDegree]
        [generateGraphs, MinDegree]
        [generateGraphs, Only4CycleFree]
        [generateGraphs, OnlyBiconnected]
        [generateGraphs, OnlyBipartite]
        [generateGraphs, OnlyConnected]
        [generateGraphs, OnlyTriangleFree]
    Headline
        generates the graphs on a given number of vertices
    Usage
        G = generateGraphs n
        G = generateGraphs(n, e)
        G = generateGraphs(n, le, ue)
    Inputs
        n:ZZ
            the number of vertices of the graphs, must be positive (see caveat)
        e:ZZ
            the number of edges in the graphs
        le:ZZ
            a lower bound on the number of edges in the graphs
        ue:ZZ
            an upper bound on the number of edges in the graphs
        MaxDegree=>ZZ
            an upper bound on the degrees of the vertices
        MinDegree=>ZZ
            a lower bound on the degrees of the vertices
        Only4CycleFree=>Boolean
            whether to only allow graphs without 4-cycles
        OnlyBiconnected=>Boolean
            whether to only allow biconnected graphs
        OnlyBipartite=>Boolean
            whether to only allow bipartite graphs
        OnlyConnected=>Boolean
            whether to only allow connected graphs
        OnlyTriangleFree=>Boolean
            whether to only allow graphs without triangles (3-cycles)
    Outputs
        G:List
            the graphs satisfying the input conditions
    Description
        Text
            This method generates all graphs on $n$ vertices subject to the 
            constraints on the number of edges.  It uses numerous options
            to allow further constraining of the output.
        Example
            generateGraphs(5, 4, 6, OnlyConnected => true)
    Caveat 
        The number of vertices $n$ must be positive as nauty cannot handle
        graphs with zero vertices.
    SeeAlso
        "Example: Generating and filtering graphs"
        generateBipartiteGraphs
///

doc ///
    Key
        generateRandomGraphs
        (generateRandomGraphs, ZZ, ZZ)
        (generateRandomGraphs, ZZ, ZZ, ZZ)
        (generateRandomGraphs, ZZ, ZZ, QQ)
        (generateRandomGraphs, ZZ, ZZ, RR)
        [generateRandomGraphs, RandomSeed]
    Headline
        generates random graphs on a given number of vertices
    Usage
        G = generateRandomGraphs(n, num)
        G = generateRandomGraphs(n, num, pq)
        G = generateRandomGraphs(n, num, pz)
    Inputs
        n:ZZ 
            the number of vertices of the graphs, must be positive (see caveat)
        num:ZZ 
            the number of random graphs to generate
        pq:QQ 
            the edge probability (between 0 and 1)
        pq:RR 
            the edge probability (between 0 and 1)
        pz:ZZ 
            the reciprocal of the edge probability (positive)
        RandomSeed=>ZZ
            the specified random seed is passed to nauty
    Outputs
        G:List
            the randomly generated graphs
    Description
        Text
            This method generates a specified number of random graphs with a given
            number of vertices.  Note that some graphs may be isomorphic.
        Text
            If the input $pq$ is included, then the edges are chosen to be
            included with probability $pq$.  If the input $pz$ is included
            and is positive, then the edges are chosen to be included with
            probability $1/pz$.
        Example
            generateRandomGraphs(5, 5, RandomSeed => 314159)
            generateRandomGraphs(5, 5)
            generateRandomGraphs(5, 5, RandomSeed => 314159)
    Caveat 
        The number of vertices $n$ must be positive as nauty cannot handle
        graphs with zero vertices.  Further, if the probability $pq$ is included,
        then it is rounded to a precision of one-hundred millionth.
    SeeAlso
        "Example: Generating and filtering graphs"
        generateRandomRegularGraphs
///

doc ///
    Key
        generateRandomRegularGraphs
        (generateRandomRegularGraphs, ZZ, ZZ, ZZ)
        [generateRandomRegularGraphs, RandomSeed]
    Headline
        generates random regular graphs on a given number of vertices
    Usage
        G = generateRandomRegularGraphs(n, num, reg) 
    Inputs 
        n:ZZ
            the number of vertices of the graphs, must be positive (see caveat)
        num:ZZ 
            the number of random graphs to generate
        reg:ZZ 
            the regularity of the generated graphs
        RandomSeed=>ZZ 
            the specified random seed is passed to nauty
    Outputs 
        G:List
            the randomly generated regular graphs
    Description
        Text
            This method generates a specified number of random graphs on
            a given number of vertices with a given regularity.
            Note that some graphs may be isomorphic.
        Example
            generateRandomRegularGraphs(5, 3, 2)
    Caveat
        The number of vertices $n$ must be positive as nauty cannot handle
        graphs with zero vertices.
    SeeAlso
        generateRandomGraphs
///

doc ///
    Key
        graph6ToSparse6
        (graph6ToSparse6, String)
    Headline
        converts a Graph6 string to a Sparse6 string
    Usage
        s6 = graph6ToSparse6 g6
    Inputs
        g6:String
            a string in nauty's Graph6 format
    Outputs
        s6:String
            a string in nauty's Sparse6 format
    Description
        Text
            This method converts a graph stored in nauty's Graph6 format
            to a graph stored in nauty's Sparse6 format.  For graphs with
            very few edges, the Sparse6 format can use dramatically less
            space.  However, for graphs with many edges, the Sparse6
            format can increase the storage requirements.
        Example
            graph6ToSparse6 "Dhc"
            graph6ToSparse6 "M????????????????"
    SeeAlso
        "Comparison of Graph6 and Sparse6 formats"
        graphToString
        stringToEdgeIdeal
        stringToGraph
        sparse6ToGraph6
///

doc ///
    Key
        graphComplement
        (graphComplement, List)
        (graphComplement, String)
        (graphComplement, Graph)
        [graphComplement, OnlyIfSmaller]
    Headline
        computes the complement of a graph
    Usage 
        L' = graphComplement L
        T = graphComplement S
        H = graphComplement G
    Inputs
        L:List
            containing graphs in various formats
        S:String
            a graph encoded in either Sparse6 or Graph6 format
        G:Graph
        OnlyIfSmaller=>Boolean
            when true, then the smaller (fewer edges) of the graph and its complement are returned
    Outputs
        L':List
            the graph complement of the elements of $L$ stored in Graph6 format
        T:String
            the graph complement of $S$ stored in the same format at $S$
        H:Graph
            the graph complement of $G$
    Description
        Text
            This method computes the graph complement of the input graph
            and returns the result in the same format.
        Example
            graphComplement "Dhc"
            graphComplement graph {{1,2},{2,3},{3,4},{4,5},{1,5}}
        Text
            Batch calls can be performed considerably faster when using the 
            List input format.  However, care should be taken as the returned
            list is entirely in Graph6 or Sparse6 format.
        Example
            G = generateBipartiteGraphs 7;
            time graphComplement G;
            time (graphComplement \ G);
///

doc ///
    Key
        graphToString
        (graphToString, List, ZZ)
        (graphToString, MonomialIdeal)
        (graphToString, Ideal)
        (graphToString, Graph)
        (graphToString, String)
    Headline
        converts a graph to a string in the Graph6 format
    Usage
        S = graphToString(E, n)
        S = graphToString I
        S = graphToString G
        S = graphToString T
    Inputs
        E:List
            a list of edge pairs
        n:ZZ
            the number of vertices in the graph, must be positive (see caveat)
        I:Ideal
            the edge ideal of a graph
        G:Graph
        T:String
            a string containing a graph; the string automatically passes through untouched
    Outputs
        S:String
            the graph converted to a Graph6 format string
    Description
        Text
            This method converts various ways of representing a graph into
            nauty's Graph6 string format.  Note that if the @TO "Ideal"@
            (or @TO "MonomialIdeal"@) passed to the method is not squarefree and monomial, then the
            method may have unknown and possibly undesired results.

            In this example, all graphs are the 5-cycle.
        Example
            graphToString({{0,1}, {1,2}, {2,3}, {3,4}, {0,4}}, 5)
            R = QQ[a..e];
            graphToString monomialIdeal (a*c, a*d, b*d, b*e, c*e)
            graphToString graph {{0,1}, {1,2}, {2,3}, {3,4}, {0,4}}
            graphToString "Dhc"
        Text
            We note that if the input is a string, then the output is simply that string returned,
            regardless of format or correctness.
    Caveat
        Notice that if using a @TO "List"@ and number of vertices input to create
        the string, then the @TO "List"@ must have vertices labeled $0$ to
        $n-1$.

        The number of vertices $n$ must be positive as nauty cannot handle
        graphs with zero vertices.
    SeeAlso
        "Comparison of Graph6 and Sparse6 formats"
        graph6ToSparse6
        sparse6ToGraph6
        stringToGraph
///

doc ///
    Key
        isPlanar
        (isPlanar, Graph)
        (isPlanar, String)
    Headline
        determines if a given graph is planar
    Usage
        p = isPlanar G
        p = isPlanar S
    Inputs
        S:String
            a graph encoded in either Sparse6 or Graph6 format
        G:Graph
    Outputs
        p:Boolean
            whether the given graph is planar
    Description
        Text
            A graph is planar if the graph can be embedded in the plane, i.e.,
            the vertices can be arranged such that no edges cross except at
            vertices.
        Example
            isPlanar graph {{0,1}, {1,2}, {2,3}, {3,4}, {0,4}}
            isPlanar graph flatten for i from 0 to 4 list for j from i+1 to 4 list {i,j}
        Text
            This method uses the program @TT "planarg"@. The
            code was written by Paulette Lieby for the Magma project and
            used with permission in the software nauty.
    SeeAlso
        onlyPlanar
///

doc ///
    Key
        neighborhoodComplements
        (neighborhoodComplements, List)
        (neighborhoodComplements, String)
        (neighborhoodComplements, Graph)
    Headline
        complements the neighborhood for each vertex, individually
    Usage
        N' = neighborhoodComplements L
        N = neighborhoodComplements S
        N = neighborhoodComplements G
    Inputs
        L:List
            containing graphs in various formats
        S:String
            a graph encoded in either Sparse6 or Graph6 format
        G:Graph
    Outputs
        N':List
            containing graphs in either Graph6 or Sparse6 format, modified as described below
        N:List
            containing graphs, in the same format as the input, modified as described below
    Description
        Text
            The method creates a list of graphs, one for each vertex of the
            original graph $G$.  The graph associated to a vertex $v$
            of $G$ has the neighborhood of $v$ complemented.  

            The method does not remove isomorphs.
        Example
            neighborhoodComplements graph {{1,2},{1,3},{2,3},{3,4},{4,5}}
    SeeAlso
        graphComplement
        neighbors
///

doc ///
    Key
        newEdges
        (newEdges, List)
        (newEdges, String)
        (newEdges, Graph)
    Headline
        replaces disjoint pairs of edges by disjoint pairs of two-chains
    Usage
        N' = newEdges L
        N = newEdges S
        N = newEdges G
    Inputs
        L:List
            containing graphs in various formats
        S:String
            a graph encoded in either Sparse6 or Graph6 format
        G:Graph
    Outputs
        N':List
            containing graphs in either Graph6 or Sparse6 format, modified as described below
        N:List
            a list of graphs, in the same format as the input, modified as described below
    Description
        Text
            The list of "new edge" graphs are formed as follows:
            Let $ab$ and $cd$ be disjoint edges of $G$.  Then the
            associated "new edge" graph $H$ is $G$ with the edges
            $ab$ and $cd$ removed, the vertices $e$ and $f$ added,
            and the new edges $ae, be, cf, df,$ and $ef$ added.
        Example
            newEdges graph {{a,b},{c,d}}
        Text
            If the List input format is used, then one should use care as
            the list may contain isomorphic pairs.
///

doc ///
    Key
        onlyPlanar
        (onlyPlanar, List, Boolean)
        (onlyPlanar, List)
    Headline
        removes non-planar graphs from a list
    Usage
        P = onlyPlanar L
        P = onlyPlanar(L, non)
    Inputs
        L:List
            containing graphs in various formats
        non:Boolean
            whether to return non-planar graphs
    Outputs
        P:List
            containing the planar graphs of $L$ in Graph6 or Sparse6 format
    Description
        Text
            A graph is planar if the graph can be embedded in the plane, i.e.,
            the vertices can be arranged such that no edges cross except at
            vertices.
        Text
            The only non-planar graph on five vertices is the complete graph.
        Example
            K5 = graph flatten for i from 0 to 4 list for j from i+1 to 4 list {i,j};
            P = onlyPlanar(generateGraphs 5, true)
            areIsomorphic(first P, K5)
        Text
            This method uses the program @TT "planarg"@. The
            code was written by Paulette Lieby for the Magma project and
            used with permission in the software nauty.
    SeeAlso
        isPlanar
///

doc ///
    Key
        relabelBipartite
        (relabelBipartite, List)
        (relabelBipartite, String)
        (relabelBipartite, Graph)
    Headline
        relabels a bipartite graph so all vertices of a given class are contiguous
    Usage
        L' = relabelBipartite L
        T = relabelBipartite S
        H = relabelBipartite G
    Inputs
        L:List
            a list of bipartite graphs in various formats
        S:String
            a bipartite graph encoded in either Sparse6 or Graph6 format
        G:Graph
            a bipartite graph
    Outputs
        L':List
            a list of graphs isomorphic to $S$
        T:String
            a graph isomorphic to $S$ encoded in either Sparse6 or Graph6 format
        H:Graph
            a graph isomorphic to $G$
    Description
        Text
            A bipartite graph can be labeled so all vertices of a given
            class are contiguous.  This method does precisely that to a
            bipartite graph.
        Example
            G = graph {{1,2},{1,4},{1,6},{3,2},{3,4},{3,6},{5,2},{5,4},{5,6}};
            relabelBipartite G
        Text
            If any of the inputs are not bipartite graphs, then the method
            throws an error.
    SeeAlso
        relabelGraph
///

doc ///
    Key
        relabelGraph
        (relabelGraph, List, ZZ, ZZ)
        (relabelGraph, List, ZZ)
        (relabelGraph, List)
        (relabelGraph, String, ZZ, ZZ)
        (relabelGraph, String, ZZ)
        (relabelGraph, String)
        (relabelGraph, Graph, ZZ, ZZ)
        (relabelGraph, Graph, ZZ)
        (relabelGraph, Graph)
    Headline
        applies a vertex invariant based refinement to a graph
    Usage
        L' = relabelGraph(L, i, a)
        L' = relabelGraph(L, i)
        L' = relabelGraph L
        T = relabelGraph(S, i, a)
        T = relabelGraph(S, i)
        T = relabelGraph S
        H = relabelGraph(G, i, a)
        H = relabelGraph(G, i)
        H = relabelGraph G
    Inputs
        L:List
            a list of graphs in various formats
        S:String
            a graph encoded in either Sparse6 or Graph6 format
        G:Graph
        i:ZZ
            a choice of invariant to order by ($0 \leq i \leq 15$, default is $0$)
        a:ZZ
            a non-negative argument passed to nauty, (default is $3$)
    Outputs
        L':List
            a list of graphs isomorphic to $S$
        T:String
            a graph isomorphic to $S$ encoded in either Sparse6 or Graph6 format
        H:Graph
            a graph isomorphic to $G$
    Description
        Text
            This method applies one of sixteen vertex invariant based refinements to a 
            graph.  See the nauty documentation for a more complete description
            of each and how the argument $a$ is used.

            The sixteen vertex invariants are:
            @UL ({
                "$i = 0$: none,",
                "$i = 1$: twopaths,",
                "$i = 2$: adjtriang(K),",
                "$i = 3$: triples,",
                "$i = 4$: quadruples,",
                "$i = 5$: celltrips,",
                "$i = 6$: cellquads,",
                "$i = 7$: cellquins,",
                "$i = 8$: distances(K),",
                "$i = 9$: indsets(K),",
                "$i = 10$: cliques(K),",
                "$i = 11$: cellcliq(K),",
                "$i = 12$: cellind(K),",
                "$i = 13$: adjacencies,",
                "$i = 14$: cellfano, and",
                "$i = 15$: cellfano2."
            } / TEX) @
        Example
            G = graph {{0,1},{1,2},{2,3},{3,4},{0,4}}
            relabelGraph G
        Text
            Note that on most small graphs, all sixteen orderings produce the same result.
    SeeAlso
        relabelBipartite
///

doc ///
    Key
        removeEdges
        (removeEdges, List)
        (removeEdges, String)
        (removeEdges, Graph)
        [removeEdges, MinDegree]
    Headline
        creates a list of graphs obtained by removing one edge from the given graph in all possible ways
    Usage
        R' = removeEdges L
        R = removeEdges S
        R = removeEdges G
    Inputs
        L:List
            containing graphs in various formats
        S:String 
            a graph encoded in either Sparse6 or Graph6 format
        G:Graph
        MinDegree=>ZZ
            the minimum degree which a returned graph can have
    Outputs
        R':List
            a list of all graphs obtained by removed one edge from the given graphs; it contains graphs in Graph6 or Sparse6 format
        R:List
            a list of all graphs obtained by removed one edge from the given graph; it contains graphs in the same format as the input
    Description
        Text
            This method creates a list of all possible graphs obtainable from
            the given graph by removing one edge.  Notice that isomorphic graphs
            are allowed within the list.
        Example
            removeEdges graph {{1,2},{1,3},{2,3},{3,4},{4,5}}
        Text
            If the List input format is used, then one should use care as
            the list may contain isomorphic pairs.
    SeeAlso
        "addEdges"
///

doc ///
    Key
        removeIsomorphs
        (removeIsomorphs, List)
    Headline
        removes all isomorphs from a list of graphs
    Usage
        M = removeIsomorphs L
    Inputs
        L:List
            containing graphs (mixed formats allowed)
    Outputs
        M:List
            containing the sub-list of non-isomorphic graphs of the input list, retaining format
    Description
        Text
            This method returns the sublist of $L$ giving all 
            non-isomorphic graphs with selection based on which comes
            first in $L$.  The format of the graph is retained.
        Example
            G = {"EhEG", graph {{0,1},{1,2},{2,3},{3,4},{4,5},{0,5}}, "DhC", graph {{0,1}}};
            removeIsomorphs G
    SeeAlso
        areIsomorphic
        "Example: Checking for isomorphic graphs"
///

doc ///
    Key
        sparse6ToGraph6
        (sparse6ToGraph6, String)
    Headline
        converts a Sparse6 string to a Graph6 string
    Usage
        g6 = sparse6ToGraph6 s6
    Inputs
        s6:String
            a string in nauty's Sparse6 format
    Outputs
        g6:String
            a string in nauty's Graph6 format
    Description
        Text
            This method converts a graph stored in nauty's Sparse6 format
            to a graph stored in nauty's Graph6 format.  The Graph6 format
            has the benefit of being a constant length dependent only
            on the number of vertices.
        Example
            sparse6ToGraph6 ":DaY_~"
            sparse6ToGraph6 ":M"
    SeeAlso
        "Comparison of Graph6 and Sparse6 formats"
        graph6ToSparse6
        graphToString
        stringToEdgeIdeal
        stringToGraph
///

doc ///
    Key
        stringToEdgeIdeal
        (stringToEdgeIdeal, String, PolynomialRing)
    Headline
        converts a Sparse6 or Graph6 String to an edge ideal in the given polynomial ring
    Usage
        I = stringToEdgeIdeal(S, R)
    Inputs
        S:String
            a string in nauty's Sparse6 or Graph6 format
        R:PolynomialRing
            a polynomial ring
    Outputs
        I:Ideal
            an ideal in the given polynomial ring
    Description
        Text
            This method converts a Sparse6 or Graph6 string $S$ to an edge
            ideal $I$ in the given polynomial ring $R$.  That is, for
            each edge $(a,b)$ in the graph given by $S$, the monomial
            $a*b$ is added as a generator to $I$.  

            Note, this method requires that the number of variables of $R$
            be the same as the number of vertices of $S$.
        Example
            R = QQ[a..e];
            stringToEdgeIdeal("Dhc", R)
        Text
            This method is almost always faster than converting the string to
            a graph and then to an edge ideal using the @TO "edgeIdeal"@ method.
    SeeAlso
        graphToString
        stringToGraph
///

doc ///
    Key
        stringToGraph
        (stringToGraph, String)
    Headline
        converts a Sparse6 or Graph6 String to a Graph
    Usage
        G = stringToEdgeIdeal S
    Inputs
        S:String
            a string in nauty's Sparse6 or Graph6 format
    Outputs
        G:Graph
    Description
        Text
            This method converts a Sparse6 or Graph6 string $S$ to an instance
            of the class Graph, stored in $G$.
        Example
            stringToGraph "Dhc"
    SeeAlso
        graphToString
        stringToEdgeIdeal
///

-- Each of these are documented within the documentation for the
-- methods which use them.
undocumented { 
    "Class2Degree2",
    "Class2DistinctNeighborhoods",
    "Class2MaxCommonNeighbors",
    "MaxDegree",
    "MinDegree",
    "NoNew3Cycles",
    "NoNew4Cycles",
    "NoNew5Cycles",
    "NoNewOddCycles",
    "NoNewSmallCycles",
    "Only4CycleFree",
    "OnlyBiconnected",
    "OnlyBipartite",
    "OnlyConnected",
    "OnlyIfSmaller",
    "OnlyTriangleFree",
    "RandomSeed"
};

-------------------
-- Tests
-------------------

-- addEdges
TEST ///
    C6 = graph {{0,1},{1,2},{2,3},{3,4},{4,5},{0,5}};
    K6 = graph flatten for i from 0 to 5 list for j from i+1 to 5 list {i,j}
    assert(#addEdges C6 == 9);
    assert(#addEdges {C6} == 9);
    assert(#addEdges K6 == 0);
    assert(#addEdges {K6} == 0);
    -- "E???" is the empty graph
    assert(#addEdges "E???" == binomial(6, 2));
///

-- areIsomorphic
TEST ///
    C6 = graph {{0,1},{1,2},{2,3},{3,4},{4,5},{0,5}};
    C = graph {{0,2},{2,4},{4,1},{1,3},{3,5},{0,5}};
    K6 = graph flatten for i from 0 to 5 list for j from i+1 to 5 list {i,j}
    assert(areIsomorphic(C6, C));
    assert(not areIsomorphic(C6, K6));
///

-- buildGraphFilter
TEST ///
    assert(buildGraphFilter {"NumVertices" => 3} == "-n3 ");
    assert(buildGraphFilter {"NumVertices" => (3,4)} == "-n3:4 ");
    assert(buildGraphFilter {"NumVertices" => (3,)} == "-n3: ");
    assert(buildGraphFilter {"NumVertices" => (,4)} == "-n:4 ");
    assert(buildGraphFilter hashTable {"NumVertices" => 3, "NegateNumVertices" => true} == "-~n3 ");
    assert(buildGraphFilter hashTable {"Regular" => true} == "-r ");
    assert(buildGraphFilter hashTable {"Regular" => false} == "-~r ");
    assert(buildGraphFilter hashTable {} == "");
///

-- countGraphs
TEST ///
    G = {graph {{0,1},{1,2},{2,3},{3,4},{4,5},{0,5}},
         graph flatten for i from 0 to 5 list for j from i+1 to 5 list {i,j},
         graph({}, Singletons => {0,1,2,3,4,5}),
         graph {{0,1},{2,3},{3,4}},
         graph({{0,1},{1,2},{2,3},{3,4}}, Singletons => {5})};
    -- Connected?
    assert(countGraphs(G, {"Connectivity" => 0, "NegateConnectivity" => true}) == 2);
    -- Bipartite?
    assert(countGraphs(G, {"Bipartite" => true}) == 4);
    -- At least 4 edges?
    assert(countGraphs(G, hashTable {"NumEdges" => (4,)}) == 3);
///

-- filterGraphs
TEST ///
    G = {graph {{0,1},{1,2},{2,3},{3,4},{4,5},{0,5}},
         graph flatten for i from 0 to 5 list for j from i+1 to 5 list {i,j},
         graph({}, Singletons => {0,1,2,3,4,5}),
         graph {{0,1},{2,3},{3,4}},
         graph({{0,1},{1,2},{2,3},{3,4}}, Singletons => {5})};
    -- Connected?
    assert(filterGraphs(G, {"Connectivity" => 0, "NegateConnectivity" => true}) === G_{0, 1});
    -- Bipartite?
    assert(filterGraphs(G, {"Bipartite" => true}) === G_{0, 2, 3, 4});
    -- At least 4 edges?
    assert(filterGraphs(G, hashTable {"NumEdges" => (4,)}) === G_{0, 1, 4});
///

-- generateBipartiteGraphs
TEST ///
    -- All bipartite graphs in R.
    assert(#generateBipartiteGraphs(6) == 57);
    -- All bipartite graphs in R with Class1 of size 3.
    assert(#generateBipartiteGraphs(6, 3) == 36);
    -- All bipartite graphs in R with Class1 of size 3 and 2 edges.
    assert(#generateBipartiteGraphs(6, 3, 2) == 3);
    -- All bipartite graphs in R with Class1 of size 3 and 1-2 edges.
    assert(#generateBipartiteGraphs(6, 3, 1, 2) == 4);
    assert(apply(toList(1..8), n -> #removeIsomorphs generateBipartiteGraphs n) == {1, 2, 3, 7, 13, 35, 88, 303}); --A033995
///

-- generateGraphs
TEST ///
    assert(#generateGraphs(6) == 156);
    assert(#generateGraphs(6, OnlyConnected => true) == 112);
    assert(#generateGraphs(6, 7) == 24);
    assert(#generateGraphs(6, 7, 8, OnlyConnected => true) == 19+22);
    assert(apply(toList(1..8), n -> #generateGraphs n) == {1, 2, 4, 11, 34, 156, 1044, 12346}); -- A000088
///

-- generateRandomGraphs
TEST ///
    assert(#generateRandomGraphs(6, 10) == 10);
    assert(#generateRandomGraphs(6, 17, 1/4) == 17);
    assert(#generateRandomGraphs(6, 42, 4) == 42);
///

-- generateRandomRegularGraphs
TEST ///
    assert(#generateRandomRegularGraphs(6, 10, 3) == 10);
    -- There is only one regular graph on 6 vertices with regularity degree 5--K6.
    assert(#unique generateRandomRegularGraphs(6, 10, 5) == 1);
///

-- graph6ToSparse6
TEST ///
    assert(graph6ToSparse6 "Dhc" == ":DaY_~");
    assert(graph6ToSparse6 "M????????????????" == ":M");
///

-- graphComplement
TEST ///
    C5 = graph {{0,1},{1,2},{2,3},{3,4},{0,4}};
    assert(#edges graphComplement C5 == 5);
    G = graph {{1,2},{2,3},{3,4},{4,5}};
    assert(areIsomorphic(graphComplement(G, OnlyIfSmaller => true), G));
    assert(#edges graphComplement G == 6);
    L = generateGraphs 6;
    assert(#graphComplement L == #L);
///

-- graphToString
TEST ///
    C5 = graph {{0,1},{1,2},{2,3},{3,4},{0,4}};
    K5 = graph flatten for i from 0 to 4 list for j from i+1 to 4 list {i,j}
    R = ZZ[a..e];
    assert(graphToString C5 == "Dhc");
    assert(graphToString ideal (a*b, b*c, c*d, d*e, a*e) == "Dhc");
    assert(graphToString monomialIdeal (a*b, b*c, c*d, d*e, a*e) == "Dhc");
    assert(graphToString "Dhc" == "Dhc");
    assert(graphToString ({{0,1}, {1,2}, {2,3}, {3,4}, {0,4}}, 5) == "Dhc");
    assert(graphToString K5 == "D~{");
    C100 = graph append(apply(99, i -> {i, i+1}), {0, 99});
    assert(graphToString C100 == "?@chCGGC@?G?_@?@??_?G?@??C??G??G??C??@???G???_??@???@????_???G???@????C????G????G????C????@?????G?????_????@?????@??????_?????G?????@??????C??????G??????G??????C??????@???????G???????_??????@???????@????????_???????G???????@????????C????????G????????G????????C????????@?????????G?????????_????????@?????????@??????????_?????????G?????????@??????????C??????????G??????????G??????????C??????????@???????????G???????????_??????????@???????????@????????????_???????????G???????????@????????????C????????????G????????????G????????????C????????????@?????????????G?????????????_????????????@?????????????@??????????????_?????????????G?????????????@??????????????C??????????????G??????????????G??????????????C??????????????@???????????????G???????????????_??????????????@???????????????@????????????????_???????????????K???????????????@");
///

-- isPlanar
TEST ///
    C6 = graph {{0,1},{1,2},{2,3},{3,4},{4,5},{0,5}};
    K6 = graph flatten for i from 0 to 5 list for j from i+1 to 5 list {i,j}
    assert(isPlanar "Dhc");
    assert(isPlanar C6);
    assert(not isPlanar K6);
///

-- neighborhoodComplements
TEST ///
    C6 = graph {{0,1},{1,2},{2,3},{3,4},{4,5},{0,5}};
    assert(#neighborhoodComplements C6 == 6);
    assert(#neighborhoodComplements {C6} == 6);
///

-- newEdges
TEST ///
    C6 = graph {{0,1},{1,2},{2,3},{3,4},{4,5},{0,5}};
    K6 = graph flatten for i from 0 to 5 list for j from i+1 to 5 list {i,j}
    -- There are nine pairs of disjoint edges in C6.
    assert(#newEdges C6 == 9);
    -- There are 45 pairs of disjoint edges in K6.
    assert(#newEdges K6 == 45);
    assert(#newEdges {K6} == 45);
///

-- onlyPlanar
TEST ///
    L = generateGraphs 5;
    assert(#onlyPlanar L == #L - 1);
    K5 = graph flatten for i from 0 to 4 list for j from i+1 to 4 list {i,j}
    assert(areIsomorphic(K5, first onlyPlanar(L, true)));
///

-- relabelBipartite
TEST ///
    C6 = graph {{0,1},{1,2},{2,3},{3,4},{4,5},{0,5}};
    G = graph {{0,3},{3,1},{1,4},{4,2},{2,5},{5,0}};
    assert(relabelBipartite C6 === G);
    assert(relabelBipartite {"EhEG"} == {"EEY_"});
///

-- relabelGraph
TEST ///
    C6 = graph {{0,1},{1,2},{2,3},{3,4},{4,5},{0,5}};
    assert(#apply(0..15, i -> relabelGraph(C6, i)) == 16);
    L = generateGraphs 5;
    assert(#relabelGraph L == #L);
///

-- removeEdges
TEST ///
    C6 = graph {{0,1},{1,2},{2,3},{3,4},{4,5},{0,5}};
    K6 = graph flatten for i from 0 to 5 list for j from i+1 to 5 list {i,j}
    assert(#removeEdges C6 == 6);
    assert(#removeEdges {C6} == 6);
    assert(#removeEdges K6 == binomial(6,2));
///

-- removeIsomorphs
TEST ///
    G = {"EhEG", graph {{0,1},{1,2},{2,3},{3,4},{4,5},{0,5}}, "DhC", graph {{0,1}}};
    assert(#removeIsomorphs G == 3);
    L = graphToString \ apply(permutations 5, P -> graph apply(5, i -> {P_i, P_((i+1)%5)}));
    assert(#removeIsomorphs L == 1);
///

-- sparse6ToGraph6
TEST ///
    assert(sparse6ToGraph6 ":DaY_~" == "Dhc");
    assert(sparse6ToGraph6 ":M" == "M????????????????");
///

-- stringToEdgeIdeal
TEST ///
    R = ZZ[a..f];
    assert(stringToEdgeIdeal("EhEG", R) == monomialIdeal (a*b, b*c, c*d, d*e, a*f, e*f));
    assert(stringToEdgeIdeal("E???", R) == monomialIdeal (0_R));
///

-- stringToGraph
TEST ///
    R = ZZ[a..f];
    assert(stringToGraph "EhEG" === graph {{0,1},{1,2},{2,3},{3,4},{4,5},{0,5}});
    assert(stringToGraph "E???" === graph({}, Singletons => {0,1,2,3,4,5}));
///

-------------------
-- HappyHappyJoyJoy
-------------------
end

restart
uninstallPackage "Nauty"
installPackage "Nauty"
check "Nauty"

-----------------------
-- For J-SAG Manuscript
-----------------------
restart

needsPackage "Nauty";
R = QQ[a..e];
graphToString cycle R
graphToString completeGraph R
edges stringToGraph("Dhc", R)

G = graph {{a, c}, {c, e}, {e, b}, {b, d}, {d, a}};
areIsomorphic(cycle R, G)
removeIsomorphs apply(permutations gens R, 
   P -> graphToString graph apply(5, i-> {P_i, P_((i+1)%5)}))

A000088 = apply(1..9, n -> #generateGraphs n)

B = apply(1..12, n -> generateGraphs(n, OnlyBipartite => true));
forestsOnly = buildGraphFilter {"NumCycles" => 0};
A005195 = apply(B, graphs -> #filterGraphs(graphs, forestsOnly))

treesOnly = buildGraphFilter {"NumCycles" => 0,
   "Connectivity" => 0, "NegateConnectivity" => true};
A000055 = apply(B, graphs -> #filterGraphs(graphs, treesOnly))

connected = buildGraphFilter {"Connectivity" => 0, 
    "NegateConnectivity" => true};
prob = n -> log(n)/n;
apply(2..30, n-> #filterGraphs(generateRandomGraphs(n, 100, 2*(prob n)), connected))
apply(2..30, n-> #filterGraphs(generateRandomGraphs(n, 100, (prob n)/2), connected))

