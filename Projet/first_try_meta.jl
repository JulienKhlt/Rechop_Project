
function neighbor_1(clusters0::Vector{Cluster})
    clusters=deepcopy(clusters0)
    nb_mouv = rand(1:1)
    cl1 = rand(clusters)
    cl2 = rand(clusters)
    println(cl1.U.u," vers ",cl2.U.u)

    for i = 1:nb_mouv
        if length(cl1.fourns)>0 && length(cl2.fourns)>0
            fourn = rand(cl1.fourns)
            deleteat!(cl1.fourns, findfirst(F->F.f==fourn.f,cl1.fourns))
            push!(cl2.fourns,fourn)
        end
    end

    return clusters,cl1,cl2
end

function calc_routes_1_cluster(clust::Cluster, instance::Instance)
    Q = new_opti_cluster(clust, instance.emballages, instance.J, 1:instance.J, 1:instance.E)
    ind_F = map(fourn->fourn.f,clust.fourns)
    d = new_d(instance.graphe.d, clust.U.u:clust.U.u, ind_F, 1, length(ind_F), instance.U)
    return remplissage_camion(Q, d, clust.U.u:clust.U.u, ind_F, 1:instance.J, 1:instance.E, instance.E, instance.emballages,instance.L)
end

function calc_routes_1_cluster_avec_pena(clust::Cluster, instance::Instance)
    ind_F = map(fourn->fourn.f,clust.fourns)
    d = new_d(instance.graphe.d, clust.U.u:clust.U.u, ind_F, 1, length(ind_F), instance.U)
    Q = new_opti_cluster_avec_pena(clust, instance.emballages, instance.J, 1:instance.J, 1:instance.E, instance.γ, instance.L, instance.cstop, instance.ccam, d)
    return remplissage_camion_bete(Q, d, clust.U.u:clust.U.u, ind_F, 1:instance.J, 1:instance.E, instance.E, instance.emballages,instance.L)
end

function calc_routes_par_cluster(clusters, instance)
    routes = []
    for clust in clusters
        routes_clust = []
        routes_clust = push!(routes_clust, calc_routes_1_cluster(clust, instance)...)
        push!(routes, routes_clust)
    end
    return routes
end

function routes_par_clust_to_routes(routes_par_clust)
    routes =[]
    for grproutes in routes_par_clust
        push!(routes,grproutes...)
    end
    return routes
end

function calc_routes(clusters, instance)
    routes = []
    for clust in clusters
        routes_clust = calc_routes_1_cluster(clust, instance)
        push!(routes, routes_clust...)
    end
    return routes
end

function calc_routes_avec_pena(clusters, instance)
    routes = []
    for clust in clusters
        println()
        println("CLUSTER ",clust.U.u)
        println()
        routes_clust = calc_routes_1_cluster_avec_pena(clust, instance)
        push!(routes, routes_clust...)
    end
    return routes
end

function remove_and_add(cl1,cl2,routes_par_cluster0,inst)
    routes_p_c = deepcopy(routes_par_cluster0)
    routes_cl1 = calc_routes_1_cluster(cl1,inst)
    routes_cl2 = calc_routes_1_cluster(cl2,inst)
    routes_p_c[cl1.U.u] = routes_cl1
    routes_p_c[cl2.U.u] = routes_cl2
    return routes_p_c
end


function recuit(inst::Instance,iter_max::Int,decr_T::Float64,s_0::Vector{Cluster},path)
    s = s_0
    routes_p_c = calc_routes_par_cluster(s_0,inst)
    sol = Solution(R=length(routes_p_c),routes=routes_par_clust_to_routes(routes_p_c))
    min_sol = sol
    ener = cost(sol,inst)
    min_glob = ener
    enerini = ener
    T = ener*0
    for k=1:iter_max
        println("Iteration ",k," sur ",iter_max)
        sn,cl1,cl2 = neighbor_1(s)
        routes_p_c = remove_and_add(cl1,cl2,routes_p_c,inst)
        sol = Solution(R=length(routes_p_c),routes=routes_par_clust_to_routes(routes_p_c))
        enern = cost(sol,inst)
        random_fac = exp(-(enern-ener)/T)
        if enern<ener || rand()<random_fac
            s = sn
            ener = enern
            println("Nouveau mouvement, energie : ", ener,"    Facteur aléatoire : ", random_fac,"     T : ",T)
            if ener<min_glob
                min_glob=ener
                min_sol=sol
                println("Amelioration du minimum : ", min_glob)
                # Ecrire la solution dans un fichier en cas d'interruption
            end
        end
        T*=decr_T
    end

    write_sol_to_file(min_sol, path)
    return (min_sol,min_glob,enerini)
end
