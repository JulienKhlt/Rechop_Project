mutable struct Cluster
    U::Usine
    fourns::Vector{Fournisseur}

    Cluster(; U, fourns) = new(U, fourns)
end


function opti_cluster(cl::Cluster, emballages, J, K, L, γ, CStop, CCam, d)::Vector{Route}
    return PNLE_entier([cl.U], cl.fourns, emballages, J, 1, size(cl.fourns, 1), size(emballages, 1), K, L, γ, CStop, CCam, d)[2]
end


function opti_clusters(clusters::Vector{Cluster})::Tuple{Vector{Vector{Route}},Solution}
    routes_par_clust = map(opti_cluster,clusters)
    routes = vec(routes_par_clust)
    R = length(routes)
    return (routes_par_clust,Solution(R=R,routes=routes))
end


function cost_cluster(solution::Solution, clust::Cluster)::Int

end