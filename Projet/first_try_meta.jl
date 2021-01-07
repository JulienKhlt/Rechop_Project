
function neighbor_1(clusters0::Vector{Cluster})::Vector{Cluster}
    clusters=deepcopy(clusters0)
    nb_mouv = rand(1:5)
    for i = 1:nb_mouv
        cl1 = rand(clusters)
        cl2 = rand(clusters)
        if length(cl1.fourns)>0 && length(cl2.fourns)>0
            println(cl1.U.u," vers ",cl2.U.u)
            fourn = rand(cl1.fourns)
            deleteat!(cl1.fourns, findfirst(F->F.f==fourn.f,cl1.fourns))
            push!(cl2.fourns,fourn)
        end
    end

    return clusters
end


function choice_clust(clusters::Vector{Cluster})::Cluster

end
function choice_fourn(cluster::Cluster)::Fournisseur

end

function neighbor_2(clusters0::Vector{Cluster})::Vector{Cluster}
    clusters=deepcopy(clusters0)
    nb_mouv = rand(1:5)
    for i = 1:nb_mouv
        cl1 = choice_clust(clusters)
        cl2 = rand(clusters)
        fourn = choice_fourn(cl1.fourns)
        deleteat!(cl1.fourns, findfirst(F->F.f==fourn.f,cl1.fourn))
        push!(cl2.fourns,fourn)
    end

    return clusters
end

function calc_routes(clusters, instance)
    routes = []
    for clust in clusters
        Q = new_opti_cluster(clust, instance.emballages, instance.J, 1:instance.J, 1:instance.E)
        ind_F = map(fourn->fourn.f,clust.fourns)
        d = new_d(instance.graphe.d, clust.U.u:clust.U.u, ind_F, 1, length(ind_F), instance.U)
        push!(routes, remplissage_camion(Q, d, clust.U.u:clust.U.u, ind_F, 1:instance.J, 1:instance.E, instance.E, instance.emballages,instance.L)...)
    end
    return routes
end


function recuit(inst::Instance,iter_max::Int,s_0::Vector{Cluster})

    s = s_0
    min_s = s_0
    routes = calc_routes(s_0,inst)
    sol = Solution(R=length(routes),routes=routes)
    println(feasibility(sol,inst))
    ener = cost(sol,inst)
    min_glob = ener
    enerini = ener
    T = ener
    for k=1:iter_max
        sn = neighbor_1(s)
        routes = calc_routes(sn,inst)
        sol = Solution(R=length(routes),routes=routes)
        println(feasibility(sol,inst))
        enern = cost(sol,inst)
        if enern<ener || rand()<exp(-(enern-ener)/T)
            s = sn
            ener = enern
            println("Nouveau mouvement, energie : ", ener)
            if ener<min_glob
                min_glob=ener
                min_s=s
                println("Amelioration du minimum : ", min_glob)
                # Ecrire la solution dans un fichier en cas d'interruption
            end
        end
        T*=0.99
    end

    return (min_s,min_glob,enerini)
end
