function creation_cluster(usines, fournisseurs, emballages, J, L)
    Asso = zeros(length(fournisseurs))
    for f in 1:length(fournisseurs)
        Asso[f] = association(fournisseurs[f], usines)
    end
    return creation_assos(Asso, usines, fournisseurs)

function creation_assos(Asso, usines, fournisseurs)
end

function association(fournisseur, usines)
end