include("Solution.jl")
include("New_PNLE.jl")



filename = "Data/maroc.csv"
filepath = joinpath(@__DIR__, filename)
instance = lire_instance(filepath)


clust1 = Cluster(U = instance.usines[1], fourns = [instance.fournisseurs[i] for i in 1:6]) 
clust2 = Cluster(U = instance.usines[2], fourns = [instance.fournisseurs[i] for i in 7:12]) 

K=3

show(instance)
routes1 = new_opti_cluster(clust1, instance.emballages, instance.J, 1:instance.J, 1:instance.E)
R1 =size(routes1,1)

println(R1)
show(routes1)

routes2 = new_opti_cluster(clust2, instance.emballages, instance.J, 1:instance.J, 1:instance.E)
R2 =size(routes2,1)

println(R2)
show(routes2)

sol = Solution(R=R2, routes=routes2)

# sol = Solution(R=R1+R2, routes=vcat(routes1,routes2))

show(sol)

println(feasibility(sol, instance))
println(cost(sol, instance, verbose=false))
