using JuMP, GLPK

function data(usines, fournisseurs, emballages, E, U, F, J)
    b⁺ = collect(usines[u].b⁺[e, j] for e = 1:E, u = 1:U, j = 1:J)
    b⁻ = collect(fournisseurs[f].b⁻[e, j] for e = 1:E, f = 1:F, j = 1:J)
    r_u = collect(usines[u].r[e, j] for e = 1:E, u = 1:U, j = 1:J)
    r_f = collect(fournisseurs[f].r[e, j] for e = 1:E, f = 1:F, j = 1:J)
    cs_u = collect(usines[u].cs[e] for e = 1:E, u = 1:U)
    cs_f = collect(fournisseurs[f].cs[e] for e = 1:E, f = 1:F)
    cexc = collect(fournisseurs[f].cexc[e] for e = 1:E, f = 1:F)
    s0_u = collect(usines[u].s0[e] for e = 1:E, u = 1:U)
    s0_f = collect(fournisseurs[f].s0[e] for e = 1:E, f = 1:F)
    l_e = collect(emballages[e].l for e = 1:E)
    return b⁺, b⁻, r_u, r_f, cs_u, cs_f, cexc, l_e, s0_u, s0_f
end


function PNLE_entier(usines, fournisseurs, emballages, J, U, F, E, K, L, γ, CStop, CCam, d, Q, notrelaxed = true)
    b⁺, b⁻, r_u, r_f, cs_u, cs_f, cexc, l_e, s0_u, s0_f = data(usines, fournisseurs, emballages, E, U, F, J)

    model = Model(GLPK.Optimizer)
    @variable(model, q[1:J, 1:K, 1:U+F, 1:U+F, 1:E], integer = notrelaxed)
    @variable(model, x[1:J, 1:K, 1:U+F, 1:U+F], Bin)


    @variable(model, sf[1:E, 1:F, 1:J] >= 0, integer = notrelaxed)
    @variable(model, su[1:E, 1:U, 1:J] >= 0, integer = notrelaxed)

    @variable(model, z⁻[1:E, 1:U, 1:J])
    @variable(model, z⁺[1:E, 1:F, 1:J])

    @variable(model, new_sf[1:E, 1:F, 1:J] >= 0)

    @variable(model, cost_su[1:E, 1:U, 1:J] >= 0)
    @variable(model, cost_sf[1:E, 1:F, 1:J] >= 0)
    @variable(model, cost_sursf[1:E, 1:F, 1:J] >= 0)

    @constraint(model, [e in 1:E, f in 1:F, j in 2:J], new_sf[e, f, j] >= sf[e, f, j-1] - b⁻[e, f, j])
    @constraint(model, [e in 1:E, f in 1:F], new_sf[e, f, 1] >= s0_f[e, f] - b⁻[e, f, 1])

    @constraint(model, [e in 1:E, f in 1:F, j in 1:J], sf[e, f, j] == new_sf[e, f, j] + z⁺[e, f, j])

    @constraint(model, [e in 1:E, u in 1:U, j in 2:J], su[e, u, j] == su[e, u, j-1] + b⁺[e, u, j] - z⁻[e, u, j])
    @constraint(model, [e in 1:E, u in 1:U], su[e, u, 1] == s0_u[e, u] + b⁺[e, u, 1] - z⁻[e, u, 1])

    @constraint(model, [e in 1:E, u in 1:U, j in 1:J], cost_su[e, u, j] >= su[e, u, j] - r_u[e, u, j])
    @constraint(model, [e in 1:E, f in 1:F, j in 1:J], cost_sf[e, f, j] >= sf[e, f, j] - r_f[e, f, j])
    @constraint(model, [e in 1:E, f in 1:F, j in 2:J], cost_sursf[e, f, j] >= b⁻[e, f, j] - sf[e, f, j-1])
    @constraint(model, [e in 1:E, f in 1:F], cost_sursf[e, f, 1] >= b⁻[e, f, 1] - s0_f[e, f])

    @constraint(model, [e in 1:E, u in 1:U, j in 1:J], z⁻[e, u, j] == sum(q[j, :, u, :, e]))
    @constraint(model, [e in 1:E, f in 1:F, j in 1:J], z⁺[e, f, j] == sum(q[j, :, :, f, e] - q[j, :, f, :, e])) 

    @constraint(model, [j in 1:J, k in 1:K], sum(q[j, k, u, f, e]*l_e[e] for e = 1:E, u in 1:U, f in 1:(U+F)) <= L)

    @constraint(model, [j in 1:J, k in 1:K, u in 1:(U+F), f in 1:(U+F)], x[j, k, u, f] >= sum(q[j, k, u, f, :]) / Q )

    @constraint(model, [j in 1:J, k in 1:K], sum(x[j, k, 1:U, :]) == 1)
    @constraint(model, [j in 1:J, k in 1:K, f in 1:(U+F), g in 1:(U+F)], sum(x[j, k, :, f]) >= x[j, k, f, g])
    @constraint(model, [j in 1:J, k in 1:K], sum(x[j, k, :, :]) <= 4)

    @objective(model, Min, sum(cost_su[e, u, j]*cs_u[e, u] for e in 1:E, u in 1:U, j in 1:J) + sum(cost_sf[e, f, j]*cs_f[e, f] for e in 1:E, f in 1:F, j in 1:J) + sum(cost_sursf[e, f, j]*cexc[e, f] for e in 1:E, f in 1:F, j in 1:J) + 
    sum(x[j, k, u, f]*γ*d[u, f] for j in 1:J, k in 1:K, u in 1:(U+F), f in 1:(U+F)) + J*K*CCam + CStop * sum(x))

    optimize!(model)

    @show(objective_value(model))
end

















# function compute_costs()
# end

# N = 4
# b = 10
# b⁻ = [2 for i in 1:N]

# model = Model(GLPK.Optimizer)
# @variable(model, x[1:N, 1:N+1, 1:3] >= 0, Int)
# @variable(model, x0[1:N] >= 0, Int)
# @variable(model, S[1:N] >= 0, Int)
# @variable(model, c[1:N, 1:N, 3] >= 0, Int)
# @variable(model, c0[1:N] >= 0, Int)


# @constraint(model, sum(x0) <= b)
# @constraint(model, [i in 1:N], S[i] == b⁻[i])
# @constraint(model, [i in 1:N], S[i] == (x[i, N+1, 1]+x[i, N+1, 2]+x[i, N+1, 3]+ sum(x[:, i, 3])))
# @constraint(model, [i in 2:3, j in 1:N], sum(x[j, :, i]) == sum(x[:, j, i-1]))
# @constraint(model, [j in 1:N], sum(x[j, :, 1]) == x0[j])
# @constraint(model, [i in 1:N], c0[i])

# @objective(model, Min, sum(c)+ sum(c0))
# optimize!(model)
# println(termination_status(model))
# println(objective_value(model))
# for i in 1:N
#     println(value(x[i,2,2]))
# end