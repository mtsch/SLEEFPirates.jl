# exported logarithmic functions

const FP_ILOGB0   = typemin(Int)
const FP_ILOGBNAN = typemin(Int)
const INT_MAX     = typemax(Int)

"""
    ilogb(x)

Returns the integral part of the logarithm of `abs(x)`, using base 2 for the
logarithm. In other words, this computes the binary exponent of `x` such that

    x = significand × 2^exponent,

where `significand ∈ [1, 2)`.

* Exceptional cases (where `Int` is the machine wordsize)
    * `x = 0`    returns `FP_ILOGB0`
    * `x = ±Inf`  returns `INT_MAX`
    * `x = NaN`  returns `FP_ILOGBNAN`
"""
function ilogb(x::FloatType)
    e = ilogbk(abs(x))
    e = ifelse(x == 0, FP_ILOGB0, e)
    e = ifelse(isnan(x), FP_ILOGBNAN, e)
    e = ifelse(isinf(x), INT_MAX, e)
    return e
end



"""
    log10(x)

Returns the base `10` logarithm of `x`.
"""
function log10(a::V) where {V <: FloatType}
    T = eltype(a)
    x = V(dmul(logk(a), MDLN10E(T)))

    x = ifelse(isinf(a), T(Inf), x)
    x = ifelse((a < 0) | isnan(a), T(NaN), x)
    x = ifelse(a == 0, T(-Inf), x)

    return x
end



"""
    log2(x)

Returns the base `2` logarithm of `x`.
"""
function log2(a::V) where {V <: FloatType}
    T = eltype(a)
    u = V(dmul(logk(a), MDLN2E(T)))

    u = ifelse(isinf(a), T(Inf), u)
    u = ifelse((a < 0) | isnan(a), T(NaN), u)
    u = ifelse(a == 0, T(-Inf), u)

    return u
end



const over_log1p(::Type{Float64}) = 1e307
const over_log1p(::Type{Float32}) = 1f38

"""
    log1p(x)

Accurately compute the natural logarithm of 1+x.
"""
@inline function log1p(a::V) where {V<:FloatType}
    T = eltype(a)
    x = V(logk2(dadd2(a, T(1.0))))

    x = ifelse(a > over_log1p(T), T(Inf), x)
    x = ifelse(a < -1, T(NaN), x)
    x = ifelse(a == -1, T(-Inf), x)
    # x = ifelse(isnegzero(a), T(-0.0), x)

    return x
end






    


@inline function log_kernel(x::FloatType64)
    c7 = 0.1532076988502701353
    c6 = 0.1525629051003428716
    c5 = 0.1818605932937785996
    c4 = 0.2222214519839380009
    c3 = 0.2857142932794299317
    c2 = 0.3999999999635251990
    c1 = 0.6666666666667333541
    # return @horner x c1 c2 c3 c4 c5 c6 c7
    @horner x c1 c2 c3 c4 c5 c6 c7
end

@inline function log_kernel(x::FloatType32)
    c3 = 0.3027294874f0
    c2 = 0.3996108174f0
    c1 = 0.6666694880f0
    # return @horner x c1 c2 c3
    @horner x c1 c2 c3
end

"""
    log(x)

Compute the natural logarithm of `x`. The inverse of the natural logarithm is
the natural expoenential function `exp(x)`
"""
@inline function log(d::V) where {V <: FloatType}
    T = eltype(d)
    m, e = splitfloat(d)
    x  = ddiv(dadd2(T(-1.0), m), dadd2(T(1.0), m))
    x2 = x.hi*x.hi
    t = log_kernel(x2)
    s = dmul(MDLN2(T), convert(T,e))
    s = dadd(s, scale(x, T(2.0)))
    s = dadd(s, x2*x.hi*t)
    r = V(s)
    r = ifelse(isinf(d), T(Inf), r)
    r = ifelse((d < 0) | isnan(d), T(NaN), r)
    r = ifelse(d == 0, T(-Inf), r)
    return r
end



# First we split the argument to its mantissa `m` and integer exponent `e` so
# that `d = m \times 2^e`, where `m \in [0.5, 1)` then we apply the polynomial
# approximant on this reduced argument `m` before putting back the exponent
# in. This first part is done with the help of the private function
# `ilogbk(x)` and we put the exponent back using

#     `\log(m \times 2^e) = \log(m) + \log 2^e =  \log(m) + e\times MLN2

# The polynomial we evaluate is based on coefficients from

#     `log_2(x) = 2\sum_{n=0}^\infty \frac{1}{2n+1} \bigl(\frac{x-1}{x+1}^{2n+1}\bigr)`

# That being said, since this converges faster when the argument is close to
# 1, we multiply  `m` by `2` and subtract 1 for the exponent `e` when `m` is
# less than `sqrt(2)/2`

# @inline function log_fast_kernel(x::FloatType64)
#     c8 = 0.153487338491425068243146
#     c7 = 0.152519917006351951593857
#     c6 = 0.181863266251982985677316
#     c5 = 0.222221366518767365905163
#     c4 = 0.285714294746548025383248
#     c3 = 0.399999999950799600689777
#     c2 = 0.6666666666667778740063
#     c1 = 2.0
#     # return @horner x c1 c2 c3 c4 c5 c6 c7 c8
#     @horner x c1 c2 c3 c4 c5 c6 c7 c8
# end
@inline function log_fast_kernel(::Val{ℯ}, x::FloatType64)
    c1 = 1.999999999999999972288314133660764626502058106566467649677782135685758742482496766144698785351773083811113458922204637526163881038549205101773551870109094623210762917254877090109553039007279469903453824801461040391573804774824166566643949526292524754553263795026695443159712389662581644078252968607010603610968
    c2 = 0.6666666666667549434460004333285267265680406869053659830901327667346266436931318257142165797477599672452425130700042740428316309949196372653611815447881258119580997738481692323354156411871615317719543696420484137927852850001277226697263099415647669280004039106068988405270447580230365723754547957178808398728031
    c3 = 0.3999999999538738726962144541414435478717381698624291782179664339024558766410194248606785773094450268048380009903025848373828228456304534683222807377791068647446307112757728076033626485118153334308099023908128861765205540920895607006054546981537610209993340090072975834472090816636562758205255232916081405490916
    c4 = 0.2857142948895397437668322514221170316614683506586039752553508157815230415821628590755444873134534482703317086469911339730832881816679155613278518336830580326583713972833021250019579928339569884449344565721099168257691128949290242593406639289400358835805201177716066926330467161068254732324976157312062181397104
    c5 = 0.2222213272064609407832488534811096903043213323448936195760022219566940033190116316148233631566934293619964683736335620450610562814540910421273386544020209082248663729359295226473378708573499720325694646886338761632152514889514576112374911673348473682348856750480831656681550267261984643811753541529379362618142
    c6 = 0.1818654653487392551668075477537833265626209821629846126426633400335635447071376344551918365876671413801628376724117217711884847602904459694588207833614683525979742338578073568440807582169681357495829253950124112087449367746242833482997053575909810310725745830457940331655678213408083578654327589717490766966316
    c7 = 0.1524699883651617684758546885725609890936381489527976937281307452249553913565153843250171402249265467319884679549763243177823555571966975970148692848138108033225746264903112492670940278404127063267504949155893965147469747805989675713477911533708565646356998159446756108541482683919621746752450341943950918560444
    c8 = 0.1538953296978747663739188355461749838905796367288249763220945925738162292410415558446630046977678608900931196974342765569666836704427957456516824211567717339130678264230162068823354062924440216282160834915006269368499669546218116339647782657742158043373280480925865755011661730676024105585113850596556788214285
    
    # return @horner x c1 c2 c3 c4 c5 c6 c7 c8
    @horner x c1 c2 c3 c4 c5 c6 c7 c8
end
@inline function log_fast_kernel(::Val{2}, x::FloatType64)
    c1 = 2.885390081777926774740337587963391752686470697574765996133470083444891120861519512296991622220723412089079177191231548172714708142318482235816576480680610952734785448442320447132165628681849517673133529587846690979418974880507488664900789156089097059610996054569326290084125678471502654166548446893122338532023
    c2 = 0.961796693926102961378386928495391595938424207149134440404480732778312340979663210431269788063894714493781166788019705851174671611070080003600398207633647592429465904114253305976485929100610421212526719593170862683559667522557899294936579940209730738921352092933643818075700304222605219379909840287720015165077
    c3 = 0.5770780162890394278273854528706340654257728320572568632943194769906014206782795171423662811759225609963039097058912006230744532836499408229020296996683361427737236690874403276328688271898375199708672755531222931943112778342087718944944239475930062972065947224509908568008815556826452609036080069051093851514719
    c4 = 0.4121985963482258893317233713653895329219961937247187525902938212418030791614989670601171640498617021581805069974492938372942662521097310303271885588961051534834143152084062233729520211313166578624228740014460226168127571506582817840795882861445281733432295086662549435665853089795110491148681367383331211653156
    c5 = 0.3205976067405248834432270866405883817579685724708723120304185738192179121685967129432280504103850651307525256102164088523101383325504692290521548379010015901361257947729248068766464395617984767730309694808014478671371484004210846383386546377909682005632339682003007230634870784176301771432154037832373961831963
    c6 = 0.2623764049675897374399611828075795820528035043402834678195862228934527298347670603110363990323094620293616051801837703306154765947894231616030376001347124009763901282915858969582585714993674594044171879858797430669924758656504158059304709147122269898951359911582928703927632984965613508778815160634440821006823
    c7 = 0.2199676960988168325549661966995124554567674873746539020720831896109731813706126058088861721617649492103067104363793480846581954569700692779507905838002757047383852895766988734919935420040379293796738154168364864473763605523658805065039735690708281857109533843972417256743512773874125120066398926457479452994093
    c8 = 0.2220240289710959406538132498293188569978091951805264791950528071212183891654240675907318516066736410222500677207442838638375330590597400913020365613995393179596880082388555123835749955456521729694538056168216831175849919088444866170319155410834510245750708062346271728171344176144233493167586972292956621704167    
    # return @horner x c1 c2 c3 c4 c5 c6 c7 c8
    @horner x c1 c2 c3 c4 c5 c6 c7 c8
end

@inline function log_fast_kernel(::Val{10}, x::FloatType64)
    c1 =  0.8685889638065036432672255818457456620537919700293854424399383732256146363051867291737996290646083904268468327485568617121891480232028305787354751638012514944407094833248397815371743068586919068331703155335228458272956632967000584692018213191915302263427674570088968450693576141175732531517678584130133488775893
    c2 = 0.289529654602206223218897458491530052216437304025126640928737786143658864009819136396293727812833113883865081710490495071577394386390336553284798095113864430166701686074384085293008322176901432559979747690473685504222412496992037568028871605354718008296002575905153882801963369202254306062241653871079893407729
    c3 = 0.1737177927412684085008505858030856254134570039101401847372412083526490838925270684560396087151125756082675171971163723816262884531013795389030201657118592808257963412538759109004335779936711829993745761261595165270595921800785766770722505651205317838265949564812751128365672552384726145990408881302861993442072
    c4 = 0.124084141671405574393119774342379038943035440967672176300349617111223279386283617245637261931967773366390542218623202064853709162387633923945101837482720858401586930272680329417249662855419483491550426930831166880694460788192553025152128890024473005464191284816736651956113517224303485887407396239605078813817
    c5 = 0.0965094961669829540665281778271879870503607562463579311776807795544766566145336804016234542308954076175565028868542245611661076354757445050297484478201748028177952545926643264467567237956842081201973429706232536334273315470353366452441368153691213892910824897647991673300813947787448822658922157919903634799232
    c6 = 0.07898316804972451278986704059544004657534078944771282690278469570981935772429141983258957479757541438522692317478446375357141436448959705067029890831066506672402437452874301364583400492390678050347427582721177656604136026871846918722378134086776956936760280411925008797490847304302379623068922461071133054013859
    c7 = 0.06621687460284276437404220222283889587447460505118960613559060231236406623915686648073020335416144993466970222767859395725920508224420109118449188766790585839731181487203895006109028946170265819774012459305958251419929926567321073232894818683941128265790381145874410375046038091980215817264367754587024710978986
    c8 = 0.0668358924784686462819357730165824743917341557202951962573347574755028338084519992412011915655131252999581138520558248266369770803727027591714823269708741953473958951570623295145882252663691038603224938441400683179259967167971897078905444705976854175284181780118155805554122865814034985253134445374766613739187
    @horner x c1 c2 c3 c4 c5 c6 c7 c8
end

@inline function log_fast_kernel(::Val{ℯ}, x::FloatType32)
    c5 = 0.2392828464508056640625f0
    c4 = 0.28518211841583251953125f0
    c3 = 0.400005877017974853515625f0
    c2 = 0.666666686534881591796875f0
    c1 = 2f0
    # return @horner x c1 c2 c3 c4 c5
    @horner x c1 c2 c3 c4 c5
end
@inline function log_fast_kernel(::Val{2}, x::FloatType32)
    c1 = 2.88539008183608973931111465797605163855459400351399679091670150619994307807932305709230255880455898882523001788391899491983367652635183189227843545539636871821101647200186975131915853092890583610850196033734515715697697545252303451919374844119991942911339078566733293749421229056798365084549286067828816391335f0
    c2 = 0.9617966217191049631079511471983452477766855280727822803767276536378636410044422070689420475579087786542928086817468309854736049531273903145228084274670593651217615221379183203388034928285734826591357927980847901606338440032331555302786596797592993793099171114989291012653957044107057443267095126328001276549215f0
    c3 = 0.577092346895436124496418053994048368787454897109979847565300121654461075967303615264336356613865144091476468885553992850165141154633791757163879758533181288454326796486333639237352641170689759463369795606769823631738673348747856212036970422229498298065338996708007695849071708840167941742938607388858010144124f0
    c4 = 0.4112062774884430872292144102146583634128259952701992109373810141836243377352557453727961104893802593899034166502781198307239642169574364520342372597806296006723519823066460247328403371685464127344456586539860933393102297655759579144420040193328399480261756827846184101221968710775674920677966868480884154531906f0
    c5 = 0.3483929578463614140008807858571049228792841000218239434906676609692043222435549289484194004801943792995337270459610071866199644093805754623761881367467842177198732930226925274643266617665940920235915835781226498423330347120803047035104419586882902933922994002620011702649787056467119273317636032117141887959942f0
    @horner x c1 c2 c3 c4 c5
end
@inline function log_fast_kernel(::Val{10}, x::FloatType32)
    c1 =  0.8685889638240124402397708951106502262202360135356954454698763954975124221040424849066825167876820875325127784493624787542409796165383940126454679616909814259580253262132903371754228716156380963198674619876749182361498397961445142358261199400985591909478187454632084248453424851342102079761821940780603198545616f0
    c2 = 0.2895296328657339288904493329122032697541659756446158536870312153495414932533066234388735996180213425285285960320369659124149855341013308711222268203432308124686350895775277211606241842893767238421488611650069250184273261408780106508058139758507081550308729508346041832759467694040676864256279697131089631717099f0
    c3 = 0.1737221066836498683203094026804327752209318893377756731259494918401339926199681736692287989621095193583635545978137901741612449570980653896864502278390604987366493020260231450208306389176678539877072993190077953368719548863200253103843475249767868540737686876012511040200964468493328048981851042321833775224372f0
    c4 = 0.1237854239293478707125637927629425829204203853315914667487437505152964085560979536798787545674711702014151928256831535140556118705532892713919312267005970112932094938487205764203670341705365514082680822781583742792219266327012272008036123492184419119821962482310107701115807828778871264690149628141482055104599f0
    c5 = 0.1048767305898517597797548767722330999824230472712341470034472461777359592830413739746852188570789846396677304208657150772765766584594750277172294014192856723183380665073137335352084472870754706334151185602395485903693315152058182538357857178779149581856966210549355606555462782599244992615178411271029676590258f0
    @horner x c1 c2 c3 c4 c5
end

"""
    log_fast(x)

Compute the natural logarithm of `x`. The inverse of the natural logarithm is
the natural expoenential function `exp(x)`
"""
@inline function log_fast(::Val{BASE}, d::FloatType, ::False) where {BASE}
    T = eltype(d)
    I = fpinttype(T)
    o = d < floatmin(T)
    d = ifelse(o, d * T(Int64(1) << 32) * T(Int64(1) << 32), d)

    e = ilogb2k(d * T(1.0/0.75))
    m = ldexp3k(d, -e)
    e = ifelse(o, e - I(64), e)
    # @show m e
    x  = (m - one(m)) / (m + one(m))
    x2 = x * x

    t = log_fast_kernel(Val{BASE}(), x2)

    x = muladd(x, t, invlog2(Val{BASE}(), T) * e)

    x = ifelse(isinf(d), T(Inf), x)
    x = ifelse((d < zero(I)) | isnan(d), T(NaN), x)
    x = ifelse(d == zero(I), T(-Inf), x)

    return x
end
# polynomial
# m ∈ (0.75,1.5)
# x = (m-1)/(m+1)
# x2 = x*x
# x*p(x2)

# log(m)/x == p( x2 )
# x = sqrt(x2)
# x*m + x = m - 1
# m - x*m = x + 1
# m = (x + 1) / (1 - x)
# function g(x2)
#     x = sqrt(x2)
#     m = (x + 1) / (1 - x)
#     log(m)/x
# end
# using Remez
# setprecision(1024) # eps(BigFloat) must be smaller than minimum in interval
# N,D,E,X = ratfn_minimax(g, [(1e-300),(0.04)], 7, 0); @show(E); N

@inline invlog2(::Val{ℯ}, ::Type{T}) where {T} = T(0.6931471805599453094172321214581765680755001343602552541206800094933936219696955)
@inline invlog2(::Val{2}, ::Type{T}) where {T} = One()
@inline invlog2(::Val{10}, ::Type{T}) where {T} = T(0.3010299956639811952137388947244930267681898814621085413104274611271081892744238)

@inline log_fast(d::AbstractSIMD{2,Float32}, ::True) = log_fast(d, False())
@inline function log_fast(::Val{BASE}, d::AbstractSIMD{W,T}, ::True) where {W,T<:Union{Float32,Float64},BASE}
    m = VectorizationBase.vgetmant(d) # m ∈ (0.75,1.5)
    e = VectorizationBase.vgetexp(T(1.3333333333333333)*d)
    en = invlog2(Val{BASE}(), T) * e
    # x  = (m - one(m)) / (m + one(m))
    x  = @fastmath (m - one(m)) / (m + one(m))
    x2 = x * x

    t = log_fast_kernel(Val{BASE}(), x2)

    return muladd(x, t, en)
end
@inline log_fast(d::AbstractSIMD) = log_fast(Val{ℯ}(), float(d))
@inline log2_fast(d::AbstractSIMD) = log_fast(Val{2}(), float(d))
@inline log10_fast(d::AbstractSIMD) = log_fast(Val{10}(), float(d))
@static if Base.libllvm_version ≥ v"11"
    @inline log_fast(::Val{BASE}, d::AbstractSIMD) where {BASE} = log_fast(Val{BASE}(), float(d), VectorizationBase.has_feature(Val(:x86_64_avx512f)))
else
    @inline log_fast(::Val{BASE}, d::AbstractSIMD) where {BASE} = log_fast(Val{BASE}(), float(d), False())
end
@inline log_fast(::Val{BASE}, d::AbstractSIMD{2,Float32}) where {BASE} = log_fast(Val{BASE}(), float(d), False())
@inline log_fast(d::Union{Float32,Float64}) = log_fast(Val{ℯ}(), d, False())
@inline log2_fast(d::Union{Float32,Float64}) = log_fast(Val{2}(), d, False())
@inline log10_fast(d::Union{Float32,Float64}) = log_fast(Val{10}(), d, False())
@generated function log_fast(::Val{BASE}, x::VecUnroll{N,1,T,T}) where {N,T,BASE}
    quote
        $(Expr(:meta,:inline))
        lx = log_fast(Val{$BASE}(), VectorizationBase.transpose_vecunroll(x))
        VecUnroll(Base.Cartesian.@ntuple $(N+1) n -> lx(n))
    end
end

