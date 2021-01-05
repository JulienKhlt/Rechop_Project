include("Solution.jl")



filename = "Data/maroc.csv"
filepath = joinpath(@__DIR__, filename)
instance = lire_instance(filepath)


clust1 = Cluster(U = instance.usines[1], fourns = [instance.fournisseurs[i] for i in 1:6]) 
clust2 = Cluster(U = instance.usines[2], fourns = [instance.fournisseurs[i] for i in 7:12]) 

K=3

routes1 = opti_cluster(clust1,instance.emballages,instance.J,K,instance.L, instance.γ,instance.cstop,instance.ccam, instance.graphe.d)
R1 =size(routes1,1)

routes2 = opti_cluster(clust2,instance.emballages,instance.J,K,instance.L, instance.γ,instance.cstop,instance.ccam, instance.graphe.d)
R2 =size(routes2,1)

sol = Solution(R=R1+R2, routes=vcat(routes1,routes2))

show(sol)

println(feasibility(sol, instance))
cost(sol, instance, verbose=false)
