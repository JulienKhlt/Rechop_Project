include("Solution.jl")

function test()
    filename = "Data/europe.csv"
    filepath = joinpath(@__DIR__, filename)
    instance = lire_instance(filepath)


    clusters = make_clusters_1_usine(instance)

    for clust in clusters
        print(clust.U.u, "     ")
        for fourn in clust.fourns
            print(fourn.f," ")
        end
        println()
    end

    routes = calc_routes_avec_pena(clusters,instance)

    sol = Solution(R = length(routes),routes=routes)
    #show(sol)
    write_sol_to_file(sol, "resultat.txt")
    println(feasibility(sol,instance))
    println(cost(sol,instance,verbose=false))

end


function test2()
    filename = "Data/europe.csv"
    filepath = joinpath(@__DIR__, filename)
    instance = lire_instance(filepath)

    clusters = make_clusters_1_usine(instance)

    println(recuit(instance,200,0.98,clusters,"resultat.txt")[2:3])
end

test()