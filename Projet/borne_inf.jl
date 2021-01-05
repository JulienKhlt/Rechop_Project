function borne_inf(instance)

    quantities = zeros(instance.E)
    necessity = zeros(instance.E)
    f_necessity = zeros(instance.F, instance.E)
    giving = zeros(instance.E)

    cost = 0

    for f in 1:instance.F
        for e in 1:instance.E
            Q = sum(instance.fournisseurs[f].b⁻[e, j] for j in 1:instance.J) - instance.fournisseurs[f].s0[e]
            f_necessity[f, e] = max(0, Q)
        end
    end


    for e in 1:instance.E
        quantities[e] = sum(instance.usines[u].s0[e] + instance.usines[u].b⁺[e, j] for u in 1:instance.U, j in 1:instance.J)
        necessity[e] = sum(f_necessity[f, e] for f in 1:instance.F)
    end

    for e in 1:instance.E
        if necessity[e] > quantities[e]
            cost += (necessity[e] - quantities[e])*instance.fournisseurs[1].cexc[e]
            giving[e] = quantities[e]
        else
            giving[e] = necessity[e]
        end
    end
    tot = sum(giving[:])
    cost += ceil(tot / instance.L)*instance.ccam

    return cost
end