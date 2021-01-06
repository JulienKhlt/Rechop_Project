include("Solution.jl")

filename = "Data/europe.csv"
filepath = joinpath(@__DIR__, filename)
instance = lire_instance(filepath)

function prod_agreg(usi::Usine)::Vector{Int}
    return vcat((usi.s0.+sum(usi.b⁺,dims=2))...)
end

function conso_agreg(fourn::Fournisseur)::Vector{Int}
    return vcat((sum(fourn.b⁻,dims=2) .- fourn.s0)...)
end

function make_clusters_1_usine(instance::Instance)::Vector{Cluster}

    arr_clus = []
    fourns_attrib = falses(instance.F)

    for usi in instance.usines
        prod_agr::Vector{Int} = prod_agreg(usi)
        prod_restante = copy(prod_agr)
        fourns_sorted_by_dist = sort(map(x->(x[2],x[1]),enumerate(instance.graphe.d[usi.v,(instance.U+1):(instance.U+instance.F)])))

        arr_fourns = []

        for fourn_dist in fourns_sorted_by_dist
            fourn = instance.fournisseurs[fourn_dist[2]]
            conso_agr::Vector{Int} = conso_agreg(fourn) 
            if !(fourns_attrib[fourn.f]) && all(conso_agr.<=prod_restante)
                push!(arr_fourns,fourn)
                prod_restante .-= conso_agr
                fourns_attrib[fourn.f] = true

                if length(arr_fourns)>2*instance.F/instance.U
                    println("cluster maxed out")
                    break
                end
            end
        end
        push!(arr_clus,Cluster(U=usi, fourns=arr_fourns))

    end
    println(fourns_attrib)

    for (i,x) in enumerate(fourns_attrib)
        if !x
            fourn = instance.fournisseurs[i]
            usis_sorted_by_dist = sort(map(x->(x[2],x[1]),enumerate(instance.graphe.d[fourn.v,1:instance.U])))
            for usi_dist in usis_sorted_by_dist
                usi = instance.usines[usi_dist[2]]
                if maximum(conso_agreg(fourn))<=prod_agreg(usi)[argmax(conso_agreg(fourn))] && length(arr_clus[usi_dist[2]].fourns)<2*instance.F/instance.U
                    push!(arr_clus[usi_dist[2]].fourns,fourn)
                    fourns_attrib[fourn.f] = true
                    break
                end
            end
        end
    end

    for (i,x) in enumerate(fourns_attrib)
        if !x
            push!(arr_clus[rand(1:instance.U)].fourns, instance.fournisseurs[i])
        end
    end

    return arr_clus
end

clusters = make_clusters_1_usine(instance)

for clust in clusters
    print(clust.U.u, "     ")
    for fourn in clust.fourns
        print(fourn.f," ")
    end
    println()
end

global K = 6
global tot_cost = 0

println()
# println("EJK(F+U)2 = ",27*21*K*(1+length(clusters[4].fourns))^2)
println("F = ",length(clusters[16].fourns))
println()
Q = new_opti_cluster(clusters[16], instance.emballages, instance.J, 1:instance.J, 1:instance.E)
t1 = size(Q, 1)
t2 = size(Q, 2)
t3 = size(Q, 3)
t4 = size(Q, 4)

#sol = Solution(R=R, routes=routes)

#println(Q)
println(t1," ",t2," ",t3," ",t4)

#println(feasibility(sol, instance))
#global tot_cost += cost(sol, instance, verbose=false)

# for clust in clusters
#     for sem in 1:3
#         for grp_el in 1:27
#             println()
#             println("EJK(F+U)2 = ",7*4*(1+length(clust.fourns))^2)
#             println("F = ",length(clust.fourns))
#             println()
#             routes = opti_cluster(clust, instance.emballages, 7 , 7*(sem-1)+1:7*sem, grp_el:grp_el, instance.U, K, instance.L, instance.γ, instance.cstop, instance.ccam, instance.graphe.d)
#             R = length(routes)

#             sol = Solution(R=R, routes=routes)

#             show(sol)

#             #println(feasibility(sol, instance))
#             global tot_cost += cost(sol, instance, verbose=false)
#         end
#     end
# end
