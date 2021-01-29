function run_2TDVP(dt, tmax, A, H, truncerr, truncdim; obs=[], bonddims=false, timed=false, kwargs...)
    A0=deepcopy(A)

    numsteps = length(collect(0:dt:tmax))-1
    times = [(i-1)*dt for i=1:numsteps+1]
    
    @printf("truncerr : %.3e, truncdim : %i \n", truncerr, truncdim)

    exp = measure(A0, obs; t=times[1])
    data = Dict([obs[i].name => reshape(exp[i], size(exp[i])..., 1) for i=1:length(obs)])

    timed && (ttdvp = Vector{Float64}(undef, numsteps))
    bonddims && (bondlist = Vector{Any}(undef, numsteps))

    F=nothing
    for tstep=1:numsteps
        bonds = bonddims(A0)
        maxbond = max(bonds...)
        bonddims && (bondlist[tstep] = bonds)
        @printf("%i/%i, t = %.3f, Dmax = %i ", tstep, numsteps, times[tstep], maxbond)
        println()
        if timed
            val, t, bytes, gctime, memallocs = @timed tdvp2sweep!(dt, A0, H, F; truncerr=truncerr, truncdim=truncdim, kwargs...)
            println("\t","ΔT = ", t)
            A0, F = val
            ttdvp[tstep] = t
        else
            A0, F = tdvp2sweep!(dt, A0, H, F; truncerr=truncerr, truncdim=truncdim, kwargs...)
        end
        exp = measure(A0, obs; t=times[tstep])
        for (i, ob) in enumerate(obs)
            data[ob.name] = cat(data[ob.name], exp[i], dims=ndims(exp[i])+1)
        end
    end
    bonddims && push!(data, "bonddims"=>bondlist)
    timed && push!(data, "deltat"=>ttdvp)
    push!(data, "times" => times)
    return A0, data
end