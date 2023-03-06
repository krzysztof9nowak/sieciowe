using Plots

function measure(address, size, mtu)
    v :: Float64 = 0
    try
        raw = read(`ping -c 1 -s $size -M $mtu $address`, String)
        r = match(r"time=(.*)$", split(raw , "\n")[2])[1]
        v = parse(Float64, split(r, " ")[1])
    catch
        return 0
    end
    return v
end

function generate(address)
    size :: Int = 16
    mtu = "do"

    times_mtu = Vector{Float64}()
    sizes_mtu = Vector{Float64}()

    times = Vector{Float64}()
    sizes = Vector{Float64}()


    while true
        t = measure(address,  size,  mtu)
        println(t, " ",size, " ",mtu)
        if t == 0 
            if mtu == "do"
                mtu = "dont"
            else
                break
            end
        else
            if mtu == "do"
                push!(times_mtu, t)
                push!(sizes_mtu, size)
            else
                push!(times, t)
                push!(sizes, size)
            end
            size = round(1.1 * size)
            if size > 65000
                break
            end
        end

    end

    scatter(sizes_mtu, times_mtu, label="Jeden fragment", legend=:topleft)
    scatter!(sizes, times, label="Wiele fragmentów")
    xlabel!("Rozmiar ładunku [bajty]")
    ylabel!("Czas [ms]")
    savefig("wykres.svg")
    gui()
end
