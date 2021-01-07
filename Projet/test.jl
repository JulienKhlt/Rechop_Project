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

    routes = []

    for clust in clusters
        Q = new_opti_cluster(clust, instance.emballages, instance.J, 1:instance.J, 1:instance.E)

        ind_F = map(fourn->fourn.f,clust.fourns)
        d = new_d(instance.graphe.d, clust.U.u:clust.U.u, ind_F, 1, length(ind_F), instance.U)
        push!(routes, remplissage_camion(Q, d, clust.U.u:clust.U.u, ind_F, 1:instance.J, 1:instance.E, instance.E, instance.emballages,instance.L)...)
    end

    sol = Solution(R = length(routes),routes=routes)
    show(sol)
    println(feasibility(sol,instance))
    println(cost(sol,instance,verbose=false))

end


function test2()
    filename = "Data/europe.csv"
    filepath = joinpath(@__DIR__, filename)
    instance = lire_instance(filepath)

    clusters = make_clusters_1_usine(instance)

    recuit(instance,20,clusters)[2:3]
end

test2()