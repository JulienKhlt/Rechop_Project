mutable struct Cluster
    U::Usine
    fourns::Vector{Fournisseur}

    Cluster(; U, fourns) = new(U, fourns)
end


function opti_cluster(cl::Cluster)::Vector{Routes}
    # On suppose le résultat optimal
end


function opti_clusters(clusters::Vector{Cluster})::Tuple{Vector{Vector{Route}},Solution}
    routes_par_clust = map(opti_cluster,clusters)
    routes = vec(routes_par_clust)
    R = length(routes)
    return (routes_par_clust,Solution(R=R,routes=routes))
end


function cost_cluster(solution::Solution, clust::Cluster)::Int

end