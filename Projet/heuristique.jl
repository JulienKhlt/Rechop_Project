function creation_cluster(usines, fournisseurs, emballages, J, L, d)
    # On associe chaque fournisseur à une usine

    Asso = zeros(length(fournisseurs))
    for f in 1:length(fournisseurs)
        Asso[f] = association(fournisseurs[f], usines, d)
    end
    return creation_assos(Asso, usines, fournisseurs)

function creation_assos(Asso, usines, fournisseurs)
    # On crée les clusters avec les associations

    Clusters = []
    for u in 1:length(usines)
        Fourns = []
        for a in 1:length(Asso)
            if (Asso[a] == u)
                push!(Fourns, fournisseurs[a])
            end
        end
        push!(Clusters, cluster(U = usines[u], fourns = Fourns))
    end
    return Clusters
end

function association(fournisseur, usines, d)
    # On associe chaque fournisseur avec l'usine la plus proche
    # A AMELIORER

    min = d[1, fournisseur.v]
    for u in 1:length(usines)
        if (d[u, fournisseur.v] <= min)
            min = d[u, fournisseur.v]
        end
    end
end