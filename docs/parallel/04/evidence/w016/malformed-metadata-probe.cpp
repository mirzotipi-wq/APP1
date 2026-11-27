// Private host-only parser/cast reproduction. This includes the existing adapter
// and shared kernel unchanged; it is neither Swift nor Metal execution.
// The reference below is deliberately made by the same canonical host kernel:
// PASS controls prove parser/metadata behavior, never independent image parity.
#define main keyfill_existing_host_harness_main
#include "../../workers/w016/scripts/verify-kernel-host.cpp"
#undef main
#include <iomanip>

static void writeU32(std::ostream& out, uint32_t value) {
    const unsigned char bytes[] = {
        static_cast<unsigned char>(value), static_cast<unsigned char>(value >> 8),
        static_cast<unsigned char>(value >> 16), static_cast<unsigned char>(value >> 24)
    };
    out.write(reinterpret_cast<const char*>(bytes), 4);
}

static void writeRows(std::ostream& out, const std::vector<float4>& values) {
    for (const float4& row : values) for (float value : {row.x, row.y, row.z, row.w}) {
        uint32_t bits;
        std::memcpy(&bits, &value, sizeof(bits));
        writeU32(out, bits);
    }
}

int main(int argc, char** argv) {
    if (argc != 4) {
        std::cerr << "usage: probe grid|tag|area-count VALUE FIXTURE\n";
        return 3;
    }
    try {
        const std::string field = argv[1];
        const float mutation = std::stof(argv[2]);
        constexpr uint width = 24, height = 16, grid = 8;
        std::vector<float4> parameters = {
            {0, 0, 3, 0.3f}, {0, 0, -1, 0.2f},
            {1, 0, 0, 0.22f}, {0, 1, 0, 3},
            {1, 1, 1, 1}, {64, 1, 0.05f, 8}
        };
        std::vector<float4> samples;
        for (uint row = 0; row < grid; ++row) for (uint col = 0; col < grid; ++col) {
            const float x = ((float(col) + 0.5f) / grid - 0.5f) * 0.4f;
            const float z = 2 + ((float(row) + 0.5f) / grid - 0.5f) * 0.4f;
            samples.push_back({x, 2, z, 1000.0f / 64});
            samples.push_back({0, -1, 0, 1});
            samples.push_back({0.95047f, 1, 1.08883f, 1});
        }
        const std::vector<float4> areas = {{0, 2, 2, 0.1f}, {1, 0, 0, 0.2f}, {0, 0, 1, 0.2f}};
        std::vector<uint8_t> reference;
        uint unsupported = 0, nonBackground = 0;
        for (uint y = 0; y < height; ++y) for (uint x = 0; x < width; ++x) {
            const uchar4 pixel = kfStudyPixel(parameters.data(), samples.data(), areas.data(), width, height, x, y);
            reference.insert(reference.end(), {pixel.x, pixel.y, pixel.z, pixel.w});
            unsupported += pixel.w == 0;
            nonBackground += pixel.x != 18 || pixel.y != 20 || pixel.z != 24;
        }
        if (unsupported != 0 || nonBackground == 0)
            throw std::runtime_error("canonical control did not provide valid surface pixels");
        if (field == "grid") parameters[5].w = mutation;
        else if (field == "tag") samples[2].w = mutation;
        else if (field == "area-count") parameters[5].y = mutation;
        else throw std::runtime_error("unknown mutation field");
        {
            std::ofstream out(argv[3], std::ios::binary | std::ios::trunc);
            for (uint32_t value : {width, height, 6u, uint32_t(samples.size()), uint32_t(areas.size()), unsupported})
                writeU32(out, value);
            writeRows(out, parameters); writeRows(out, samples); writeRows(out, areas);
            out.write(reinterpret_cast<const char*>(reference.data()), reference.size());
            out.close();
            if (!out) throw std::runtime_error("fixture write failed");
        }
        std::cout << "field=" << field << " value=" << std::setprecision(10) << mutation
                  << " finite=" << isfinite(mutation) << " canonical_surface_pixels=" << nonBackground
                  << " canonical_unsupported=" << unsupported << " fixture=" << argv[3]
                  << " reference=same-kernel-canonical-control\n" << std::flush;
        char* hostArguments[] = {argv[0], argv[3]};
        return keyfill_existing_host_harness_main(2, hostArguments);
    } catch (const std::exception& error) {
        std::cerr << "probe setup error: " << error.what() << '\n';
        return 3;
    }
}
