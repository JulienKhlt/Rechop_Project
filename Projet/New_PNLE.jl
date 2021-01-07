include("Resolution_PNLE.jl")

function New_PNLE_entier(usines, fournisseurs, emballages, J, U, F, E, ind_J, ind_E, s0_u, s0_f, notrelaxed = true)
    # On résout le PNLE avec K camions disponibles par jour de manière optimale
    
    # On récupère les données liées à notre instance ou cluster
    b⁺, b⁻, r_u, r_f, cs_u, cs_f, cexc = data(usines, fournisseurs, emballages, ind_E, U, F, ind_J)
    
    model = Model(optimizer_with_attributes(Gurobi.Optimizer,"TimeLimit"=>100,"OutputFlag"=>0))
    @variable(model, q[1:J, 1:U, 1:F, 1:E] >= 0, integer = notrelaxed)


    # Le stockage dans les fournisseurs, usines
    @variable(model, sf[1:E, 1:F, 1:J] >= 0, integer = notrelaxed)
    @variable(model, su[1:E, 1:U, 1:J] >= 0, integer = notrelaxed)

    # Les quantités qui quittent l'usine u, et celle par camion
    @variable(model, z⁻[1:E, 1:U, 1:J] >= 0)

    # Les quantités qui entre dans un fournisseurs
    @variable(model, z⁺[1:E, 1:F, 1:J] >= 0)

    # Le max dans le stock des fournisseurs, neg est la quantité que l'on doit envoyées en utilisant des cartons
    @variable(model, new_sf[1:E, 1:F, 1:J] >= 0)
    @variable(model, pos[1:E, 1:F, 1:J] >= 0)
    @variable(model, neg[1:E, 1:F, 1:J] >= 0)

    # Le max des stocks
    @variable(model, cost_su[1:E, 1:U, 1:J] >= 0)
    @variable(model, cost_sf[1:E, 1:F, 1:J] >= 0)

    # Calcul du max du stock des fournisseurs
    @constraint(model, [e in 1:E, f in 1:F, j in 2:J], pos[e, f, j] == (sf[e, f, j-1] - b⁻[e, f, j]) + neg[e, f, j])
    @constraint(model, [e in 1:E, f in 1:F], pos[e, f, 1] == (s0_f[e, f] - b⁻[e, f, 1]) + neg[e, f, 1])
    @constraint(model, [e in 1:E, f in 1:F, j in 2:J], new_sf[e, f, j] == (sf[e, f, j-1] - b⁻[e, f, j])/2 + (pos[e, f, j] + neg[e, f, j])/2)
    @constraint(model, [e in 1:E, f in 1:F], new_sf[e, f, 1] == (s0_f[e, f] - b⁻[e, f, 1])/2 + (pos[e, f, 1] + neg[e, f, 1])/2)

    # Calcul des stocks
    @constraint(model, [e in 1:E, f in 1:F, j in 1:J], sf[e, f, j] == new_sf[e, f, j] + z⁺[e, f, j])

    @constraint(model, [e in 1:E, u in 1:U, j in 2:J], su[e, u, j] == su[e, u, j-1] + b⁺[e, u, j] - z⁻[e, u, j])
    @constraint(model, [e in 1:E, u in 1:U], su[e, u, 1] == s0_u[e, u] + b⁺[e, u, 1] - z⁻[e, u, 1])

    # Calcul des max des stocks
    @constraint(model, [e in 1:E, u in 1:U, j in 1:J], cost_su[e, u, j] >= su[e, u, j] - r_u[e, u, j])
    @constraint(model, [e in 1:E, f in 1:F, j in 1:J], cost_sf[e, f, j] >= sf[e, f, j] - r_f[e, f, j])

    # Calcul des z
    @constraint(model, [e in 1:E, u in 1:U, j in 1:J], z⁻[e, u, j] == sum(q[j, u, :, e]))
    @constraint(model, [e in 1:E, f in 1:F, j in 1:J], z⁺[e, f, j] == sum(q[j, :, f, e]))


    @objective(model, Min, sum(cost_su[e, u, j]*cs_u[e, u] for e in 1:E, u in 1:U, j in 1:J) + sum(cost_sf[e, f, j]*cs_f[e, f] for e in 1:E, f in 1:F, j in 1:J) + sum(neg[e, f, j]*cexc[e, f] for e in 1:E, f in 1:F, j in 1:J))

    optimize!(model)
    @show(objective_value(model))

    Q = zeros(J, U, F, E)
    for j in 1:J
        for u in 1:U
            for f in 1:F
                for e in 1:E
                    Q[j, u, f, e] = value(q[j, u, f, e])
                end
            end
        end
    end
    return Q
end