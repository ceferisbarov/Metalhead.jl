"""
    PatchEmbedding(imsize::NTuple{2} = (224, 224); inchannels = 3, patch_size = (16, 16), 
                   embedplanes = 768, norm_layer = planes -> identity, flatten = true)

Patch embedding layer used by many vision transformer-like models to split the input image into 
patches.

# Arguments:
- `imsize`: the size of the input image
- `inchannels`: the number of channels in the input image
- `patch_size`: the size of the patches
- `embedplanes`: the number of channels in the embedding
- `norm_layer`: the normalization layer - by default the identity function but otherwise takes a 
                single argument constructor for a normalization layer like LayerNorm or BatchNorm
- `flatten`: set true to flatten the input spatial dimensions after the embedding
"""
function PatchEmbedding(imsize::NTuple{2} = (224, 224); inchannels = 3, patch_size = (16, 16), 
                        embedplanes = 768, norm_layer = planes -> identity, flatten = true)

  im_height, im_width = imsize
  patch_height, patch_width = patch_size

  @assert (im_height % patch_height == 0) && (im_width % patch_width == 0)
  "Image dimensions must be divisible by the patch size."
  
  return Chain(Conv(patch_size, inchannels => embedplanes; stride = patch_size),
               flatten ? x -> permutedims(reshape(x, (:, size(x, 3), size(x, 4))), (2, 1, 3)) 
                       : identity,
               norm_layer(embedplanes))
end

"""
    ViPosEmbedding(embedsize, npatches; init = (dims) -> rand(Float32, dims))

Positional embedding layer used by many vision transformer-like models.
"""
struct ViPosEmbedding{T}
  vectors::T
end

ViPosEmbedding(embedsize, npatches; init = (dims::NTuple{2, Int}) -> rand(Float32, dims)) = 
  ViPosEmbedding(init((embedsize, npatches)))

(p::ViPosEmbedding)(x) = x .+ p.vectors

@functor ViPosEmbedding

"""
    ClassTokens(dim; init = Flux.zeros32)

Appends class tokens to an input with embedding dimension `dim` for use in many vision transformer models.
"""
struct ClassTokens{T}
  token::T
end

ClassTokens(dim::Integer; init = Flux.zeros32) = ClassTokens(init(dim, 1, 1))

function (m::ClassTokens)(x)
  tokens = repeat(m.token, 1, 1, size(x, 3))
  return hcat(tokens, x)
end

@functor ClassTokens
