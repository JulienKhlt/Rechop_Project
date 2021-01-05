include("divide_clean.jl")



filename = "Data/maroc.csv"
filepath = joinpath(@__DIR__, filename)
instance = lire_instance(filepath)
instances = instances_par_emballage(instance)


K = 4
global tot_cost = 0
for instance1el in instances
    instance1 = instance1el.instance
    show(instance1)

    R, routes = PNLE_entier(instance1.usines, instance1.fournisseurs, instance1.emballages, instance1.J, instance1.U, instance1.F, instance1.E, K, instance1.L, instance1.γ, instance1.cstop, instance1.ccam, instance1.graphe.d)
    sol = Solution(R=R, routes=routes)
    # show(sol)
    # println(feasibility(sol, instance1))
    global tot_cost += cost(sol, instance1, verbose=false)
    println(tot_cost)
end

println(tot_cost)