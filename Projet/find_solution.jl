include("Solution.jl")
include("New_PNLE.jl")
include("descente_locale.jl")

filename = "Data/france.csv"
filepath = joinpath(@__DIR__, filename)
instance = lire_instance(filepath)

s0_u, s0_f = stock_ini(instance.usines, instance.fournisseurs, 1:instance.E, instance.U, instance.F)

Q = New_PNLE_entier_avec_pena(instance.usines, instance.fournisseurs, instance.emballages, instance.graphe.d, instance.cstop, instance.ccam, instance.γ, instance.L, instance.J, instance.U, instance.F, instance.E, 1:instance.J, 1:instance.E, s0_u, s0_f, false)
dispos =  creation_dispo(instance.usines, instance.U, 1:instance.E, 1:instance.J, Q)

routes = remplissage_camion_ultime(Q, instance.graphe.d, 1:instance.U, 1:instance.F, 1:instance.J, 1:instance.E, instance.E, instance.emballages, instance.L, creation_dispo(instance.usines, instance.U, 1:instance.E, 1:instance.J, Q))
routes = descente_locale(routes, instance, 1000)
# routes = remplissage_camion_bete(Q, instance.graphe.d, 1:instance.U, 1:instance.F, 1:instance.J, 1:instance.E, instance.E, instance.emballages, instance.L)
# routes = remplissage_camion(Q, instance.graphe.d, 1:instance.U, 1:instance.F, 1:instance.J, 1:instance.E, instance.E, instance.emballages, instance.L)
Sol = Solution(R = length(routes), routes = routes)

println(length(routes))

# write_sol_to_file(sol, "resultat.txt")
show(Sol)
println(feasibility(Sol,instance))
println(cost(Sol,instance,verbose=true))