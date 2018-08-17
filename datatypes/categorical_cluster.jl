## Define a particle consisting of all cluster variables for a Categorical mixture
mutable struct CategoricalCluster
  n::Vector{Int64}        # count of cluster members
  counts::Vector{Array{Int64}}    # count of occurrence of levels
  c::Vector{Int64}        # The allocation vector
  # ζ::Vector{Float64}      # logprob
  CategoricalCluster(dataFile, N) = new(Vector{Int64}(zeros(Int64, N)),
                                        [zeros(Int64, maximum(dataFile), N) for d = 1:size(dataFile, 2)],
                                        Vector{Int64}(zeros(Int64, size(dataFile, 1))))
                                        # , Vector{Float64}(zeros(Float64, N)))
end

function calc_logprob!(logprob, obs::Array{Int64}, cl::CategoricalCluster)
  Q = length(obs)
  for n in 1:length(logprob)
      # @inbounds cl.ζ[n] = - log(cl.n[n] + 0.5 * size(cl.counts[1], 2)) * length(obs)
      @inbounds logprob[n] = - Base.Math.JuliaLibm.log(cl.n[n] + 0.5 * size(cl.counts[1], 1)) * Q
      if cl.n[n] == 0
          @inbounds logprob[n] += Base.Math.JuliaLibm.log(0.5) * Q
      else
          for q in 1:Q
              @fastmath @inbounds logprob[n] += Base.Math.JuliaLibm.log(0.5 + cl.counts[q][obs[q], n])
          end
      end
  end
end

function particle_add!(cl::CategoricalCluster, obs::Array{Int64}, i::Int64, sstar::Int64)
  @inbounds cl.n[sstar]     += Int64(1)
  @simd for q = 1:length(obs)
    @inbounds cl.counts[q][obs[q], sstar] += Int64(1)
  end
    @inbounds cl.c[i]         = Int64(sstar)
  return
end

function particle_reset!(cl::CategoricalCluster)
  for k = 1:length(cl.counts)
    cl.counts[k] .= Int64(0)
  end
  cl.n .= Int64(0)
  return
end