using PyPlot: pygui
pygui(true)
using Plots
pyplot()
using Random

include("code_Julia/dimensions.jl")
include("code_Julia/emballage.jl")
include("code_Julia/usine.jl")
include("code_Julia/fournisseur.jl")
include("code_Julia/graphe.jl")
include("code_Julia/instance.jl")

include("code_Julia/route.jl")
include("solution.jl")

include("code_Julia/plot.jl")
include("code_Julia/feasibility.jl")
include("code_Julia/cost.jl")

include("code_Julia/write.jl")
include("cluster.jl")


# data_petite = open(joinpath( "sujet", "petite.csv")) do file
#     readlines(file)
# end

# instance_petite = lire_instance(joinpath("sujet", "petite.csv"))

# println(instance_petite)


function neighbor_1(clusters0::Vector{Cluster}, routes_par_clust::Vector{Vector{Route}})::Vector{Cluster}
    clusters=deepcopy(clusters0)
    nb_mouv = rand(1:5)
    for i = 1:nb_mouv
        cl1 = rand(clusters)
        cl2 = rand(clusters)
        fourn = rand(cl1.fourns)
        deleteat!(cl1.fourns, findfirst(F->F.f==fourn.f,cl1.fourn))
        push!(cl2.fourns,fourn)
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


function recuit(inst::Instance,iter_max::Int,s_0::Vector{Cluster})::Tuple{Vector{Cluster},Int}

    s = s_0
    min_s = s_0
    [routes_par_clust,sol_int] = opti_clusters(s)
    ener = cost(sol_int,inst)
    min_glob = ener
    T = Ener
    for k=1:iter_max
        sn = neighbor_1(s)
        [routes_par_clust,sol_int] = opti_clusters(sn)
        enern = cost(sol_int,inst)
        if enern<ener || rand()<exp(-(enern-ener)/T)
            s = sn
            ener = enern
            if ener<min_glob
                min_glob=ener
                min_s=s
                # Ecrire la solution dans un fichier en cas d'interruption
            end
        end
        T*=0.99
    end

    return (min_s,min_glob)
end
