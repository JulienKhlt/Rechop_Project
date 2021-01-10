include("Solution.jl")
include("New_PNLE.jl")

filename = "Data/petite.csv"
filepath = joinpath(@__DIR__, filename)
instance = lire_instance(filepath)

s0_u, s0_f = stock_ini(instance.usines, instance.fournisseurs, 1:instance.E, instance.U, instance.F)

New_PNLE_entier_avec_pena(instance.usines, instance.fournisseurs, instance.emballages, instance.graphe.d, instance.cstop, instance.ccam, instance.γ, instance.L, instance.J, instance.U, instance.F, instance.E, 1:instance.J, 1:instance.E, s0_u, s0_f, false)