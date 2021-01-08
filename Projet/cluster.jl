mutable struct Cluster
    U::Usine
    fourns::Vector{Fournisseur}

    Cluster(; U, fourns) = new(U, fourns)
end


function opti_cluster(cl::Cluster, emballages, J, ind_J, ind_E, U0, K, L, γ, CStop, CCam, d)::Vector{Route}
    # Optimise sur un cluster sans qu'on lui donne de stock initial, le PNLE peut renvoyer le stock final si besoin
    s0_u, s0_f = stock_clu_ini(cl::Cluster, ind_E)
    return PNLE_entier([cl.U], cl.fourns, emballages, J, 1, size(cl.fourns, 1), size(ind_E, 1), ind_J, [cl.U.u], collect(cl.fourns[i].f for i in 1:size(cl.fourns, 1)), ind_E, size(emballages, 1), K, L, γ, CStop, CCam, crea_d(cl, d, U0), s0_u, s0_f)[2]
end

function new_opti_cluster(cl::Cluster, emballages, J, ind_J, ind_E)
    # Optimise sur un cluster sans qu'on lui donne de stock initial, le PNLE peut renvoyer le stock final si besoin
    s0_u, s0_f = stock_clu_ini(cl::Cluster, ind_E)
    return New_PNLE_entier([cl.U], cl.fourns, emballages, J, 1, size(cl.fourns, 1), size(ind_E, 1), ind_J, ind_E, s0_u, s0_f)
end

function new_opti_cluster_avec_pena(cl::Cluster, emballages, J, ind_J, ind_E, γ, L, CStop, CCam, d)
    # Optimise sur un cluster sans qu'on lui donne de stock initial, le PNLE peut renvoyer le stock final si besoin
    s0_u, s0_f = stock_clu_ini(cl::Cluster, ind_E)
    return New_PNLE_entier_avec_pena([cl.U], cl.fourns, emballages, d, CStop, CCam, γ, L, J, 1, size(cl.fourns, 1), size(ind_E, 1), ind_J, ind_E, s0_u, s0_f)
end

function new_opti_cluster(cl::Cluster, emballages, J, ind_J, ind_E, s0_u, s0_f)
    # Optimise sur un cluster sans qu'on lui donne de stock initial, le PNLE peut renvoyer le stock final si besoin
    return New_PNLE_entier([cl.U], cl.fourns, emballages, J, 1, size(cl.fourns, 1), size(ind_E, 1), ind_J, ind_E, s0_u, s0_f)
end

function opti_cluster(cl::Cluster, emballages, J, ind_J, ind_E, U0, K, L, γ, CStop, CCam, d, s0_u, s0_f)::Vector{Route}
    # Optimise sur un cluster en lui donnant un stock initial utile si on décompose en jour, le PNLE peut renvoyer le stock final si besoin
    return PNLE_entier([cl.U], cl.fourns, emballages, J, 1, size(cl.fourns, 1), size(ind_E, 1), ind_J, [cl.U.u], collect(cl.fourns[i].f for i in 1:size(cl.fourns, 1)), ind_E, size(emballages, 1), K, L, γ, CStop, CCam, crea_d(cl, d, U0), s0_u, s0_f)[2]
end

function stock_clu_ini(cl::Cluster, ind_E)
    return stock_ini([cl.U], cl.fourns, ind_E, 1, size(cl.fourns, 1))
end

function crea_d(cl::Cluster, d, U0)
    new_d(d, [cl.U.u], collect(cl.fourns[i].f for i in 1:size(cl.fourns, 1)), 1, size(cl.fourns, 1), U0)
end

function opti_clusters(clusters::Vector{Cluster})::Tuple{Vector{Vector{Route}},Solution}
    routes_par_clust = map(opti_cluster,clusters)
    routes = vec(routes_par_clust)
    R = length(routes)
    return (routes_par_clust,Solution(R=R,routes=routes))
end


function cost_cluster(solution::Solution, clust::Cluster)::Int

end