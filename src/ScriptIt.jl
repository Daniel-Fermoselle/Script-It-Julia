module ScriptIt
export startScript

using Juno
using Atom
using Khepri
using JuliaInterpreter
using Core

isControlFlow = true #true = control flow, false = last call

function extractCode(filePath)
    beforeAll = time()
    backend(autocad)
    f=  with(traceability, false) do
            all_shapes()
        end
    s=""
    adToolString = "using Khepri"
    backendString = "backend(autocad)\ndelete_all_shapes()\nclear_trace!()"
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
    Khepri.ACADGetHandleFromShape(connection(current_backend()), Khepri.ref(shape).value)
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
end

end # module
