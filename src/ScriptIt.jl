module ScriptIt
export startScript, toggle_unique_key_backend

using Juno
using Atom
using Khepri
using JuliaInterpreter
using Core

isControlFlow = true #true = control flow, false = last call
is_autocad = false #to be used for the unique_key function in order to check reverseHighlight

function toggle_unique_key_backend()
    global is_autocad=!is_autocad
    @info "Unique key for: $(is_autocad ? "autocad backend" : "all backends except autocad")."
end

function script_it_start()
    @info "Welcome to ScriptIt! If you need help press ctrl+alt+h."
end

function extractCode(filePath)
    beforeAll = time()
    #backend(autocad)
    f=  with(traceability, false) do
            all_shapes()
        end
    s=""
    adToolString = "using Khepri"
    backendString = "delete_all_shapes()\nclear_trace!()"
    s = string(adToolString,"\n",backendString, "\n")
    temp_range_to_shape_Dictionary = Dict()
    for el in f
        elementString = string(meta_program(el))
        s = string(s,elementString,"\n")
    end
    afterAll = time()
    s
end

function toggleControlFlow()
    global isControlFlow=!isControlFlow
    @info "Highlight mode: $(isControlFlow ? "control flow" : "last call")."
end

function changeDetected()
    @info "Free-Refactoring modifications detected. Re-running code."
end

function toggleTraceability(toggle)
    @info "Traceability mode: $(toggle ? "On" : "Off")."
end

function toggleFreeForAllRefactoring(toggle)
    @info "Free For All Refactoring mode: $(toggle ? "On" : "Off")."
end

function highlightShape(linesAndTabPath)
    currentTabPath = Symbol(linesAndTabPath[1])
    lines = linesAndTabPath[2]
    shapesToHighlight = Shape[]
    if (lines != "")
        lineList = split(lines,",")
        for line in lineList
            if (line!="")
                lineToHighlight = parse(Int, line)
                append!(shapesToHighlight, source_shapes(currentTabPath, lineToHighlight))
            end
        end
    end
    highlight_shapes(shapesToHighlight)
end


function reverseHighlight()
    highlight_shapes(Shape[])
    @info("Select every shape you want and then press the enter key.");
    selected_shapes = select_shapes()
    actualCodeLinesHighlighted = []
    fileAndLinesToHighlight = Dict()
    stringRanges = ""
    for shape in selected_shapes
        refValVal = unique_key(shape) #TODO see new method with AML
        for dShape in keys(Khepri.shape_to_file_locations)
            dictShape = unique_key(dShape)
            if(refValVal == dictShape && length(Khepri.shape_to_file_locations[dShape])>0)
                if(isControlFlow)
                    actualCodeLinesHighlighted = vcat(actualCodeLinesHighlighted,[Khepri.shape_to_file_locations[dShape]])
                else
                    actualCodeLinesHighlighted = vcat(actualCodeLinesHighlighted,first(Khepri.shape_to_file_locations[dShape]))
                end
            end
        end
    end
    actualCodeLinesHighlighted = unique(actualCodeLinesHighlighted)
    fileAndLinesToHighlight = convertToDictAndToList(actualCodeLinesHighlighted)
    #println("files and lines to highlight: ", fileAndLinesToHighlight)
    return fileAndLinesToHighlight
end

function convertToDictAndToList(list)
    tempDict=Dict()
    file = nothing
    for el in list
        lineJoin = []
        if (isa(el, Tuple)) #This if is necessary to allow the reverseHighlight of last function call mode
            file = string(el[1])
            line = el[2]
            lineJoin = vcat(lineJoin, line)
        else
            for lineIter in el
                file = string(lineIter[1])
                line = lineIter[2]
                lineJoin = vcat(lineJoin, line)
            end
        end
        if(haskey(tempDict,file))
            tempDict[file] = vcat(tempDict[file],[lineJoin])
        else
            tempDict[file] = [lineJoin]
        end
    end
    finalList = []
    for key in keys(tempDict)
        finalList = vcat(finalList, [[key, unique(tempDict[key])]])
    end
    return finalList
end

function unique_key(shape) #TODO improve this thing with AML
    if is_autocad
        Khepri.ACADGetHandleFromShape(connection(current_backend()), Khepri.ref(shape).value)
    else
        shape
    end
end

function isEmpty()
    if (all_shapes() == [])
        return true
    else
        return false
    end
end

function startScript()
    Atom.handle(extractCode, "extractCode")
    Atom.handle(highlightShape, "highlightShape")
    Atom.handle(toggleControlFlow, "toggleControlFlow")
    Atom.handle(changeDetected, "changeDetected")
    Atom.handle(toggleTraceability, "toggleTraceability")
    Atom.handle(toggleFreeForAllRefactoring, "toggleFreeForAllRefactoring")
    Atom.handle(reverseHighlight, "reverseHighlight")
    Atom.handle(isEmpty, "isEmpty")
    Atom.handle(script_it_start, "script_it_start")
end

function __init__()
    @eval Main using Khepri
    traceability(true)
    excluded_modules([Base, Khepri, Atom, Atom.CodeTools, Base.CoreLogging,ScriptIt])
    ScriptIt.startScript()
end

end # module
