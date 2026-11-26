// Worker 036: fixed local candidate-only numeric unit test, no file parser.
// Float vector shims match scripts/verify-kernel-host.cpp. No GPU claim.
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <iomanip>
#include <iostream>
#include <limits>
#include <vector>
using std::abs; using std::min; using std::max; using std::isfinite;
using std::sqrt; using std::pow; using std::floor; using std::clamp;
using uint = uint32_t;
struct float3 {
    float x,y,z;
    float3(float a,float b,float c):x(a),y(b),z(c){}
    float3 operator+(float3 b) const {return {x+b.x,y+b.y,z+b.z};}
    float3 operator-(float3 b) const {return {x-b.x,y-b.y,z-b.z};}
    float3 operator-() const {return {-x,-y,-z};}
    float3 operator*(float3 b) const {return {x*b.x,y*b.y,z*b.z};}
    float3 operator*(float s) const {return {x*s,y*s,z*s};}
    float3 operator/(float s) const {return {x/s,y/s,z/s};}
    float3& operator+=(float3 b) {*this=*this+b;return *this;}
};
struct float4 {float x,y,z,w;};
struct uchar4 {
    uint8_t x,y,z,w;
    uchar4(int a,int b,int c,int d):x((uint8_t)a),y((uint8_t)b),z((uint8_t)c),w((uint8_t)d){}
};
inline float dot(float3 a,float3 b){return a.x*b.x+a.y*b.y+a.z*b.z;}
inline float3 normalize(float3 a){return a/sqrt(dot(a,a));}
#include "candidate-StudyKernel.h"

static void printPixel(uchar4 c) {
    std::cout << unsigned(c.x) << ',' << unsigned(c.y) << ',' << unsigned(c.z) << ',' << unsigned(c.w);
}
enum class Field { Samples, Areas, Grid, Tag };
struct Case { const char* name; Field field; float value; };

int main() {
    constexpr uint width=24,height=16,x=12,y=8;
    std::vector<float4> parameters={{0,0,3,0.3f},{0,0,-1,0.2f},
        {1,0,0,0.22f},{0,1,0,3},{1,1,1,1},{64,1,0.05f,8}};
    // Full contractual capacity plus one record for each max+1 test.
    std::vector<float4> samples;
    samples.reserve(769*3);
    for(uint i=0;i<769;++i) {
        const uint col=i%8,row=(i/8)%8;
        const float sx=((float(col)+0.5f)/8-0.5f)*0.4f;
        const float sz=2+((float(row)+0.5f)/8-0.5f)*0.4f;
        samples.push_back({sx,2,sz,1000.0f/64});
        samples.push_back({0,-1,0,1});
        samples.push_back({0.95047f,1,1.08883f,1});
    }
    std::vector<float4> areas;
    areas.reserve(13*3);
    for(uint i=0;i<13;++i) {
        areas.push_back({0,2,2,0.1f}); areas.push_back({1,0,0,0.2f}); areas.push_back({0,0,1,0.2f});
    }
    std::cout << "host_cpp_only=1 parser_used=0 sample_records=" << samples.size()/3
              << " area_records=" << areas.size()/3 << " dimensions=" << width << 'x' << height
              << " pixel=" << x << ',' << y << '\n';
    const uchar4 control=kfStudyPixel(parameters.data(),samples.data(),areas.data(),width,height,x,y);
    const bool controlPass=control.w==255 && !(control.x==18 && control.y==20 && control.z==24)
                          && (control.x>0 || control.y>0 || control.z>0);
    std::cout << "valid-control pixel="; printPixel(control);
    std::cout << " result=" << (controlPass?"PASS":"FAIL") << '\n' << std::flush;
    if(!controlPass) return 1;

    const float nan=std::numeric_limits<float>::quiet_NaN();
    const Case cases[]={
        {"samples-negative",Field::Samples,-1}, {"samples-fractional",Field::Samples,64.5f},
        {"samples-max-plus-one",Field::Samples,769}, {"samples-nan",Field::Samples,nan},
        {"samples-large",Field::Samples,4294967296.0f},
        {"areas-negative",Field::Areas,-1}, {"areas-fractional",Field::Areas,1.5f},
        {"areas-max-plus-one",Field::Areas,13}, {"areas-nan",Field::Areas,nan},
        {"areas-large",Field::Areas,4294967296.0f},
        {"grid-negative",Field::Grid,-1}, {"grid-fractional",Field::Grid,8.5f},
        {"grid-nine",Field::Grid,9}, {"grid-nan",Field::Grid,nan},
        {"grid-large",Field::Grid,4294967296.0f},
        {"tag-negative",Field::Tag,-1}, {"tag-fractional",Field::Tag,1.5f},
        {"tag-above-area-count",Field::Tag,2}, {"tag-nan",Field::Tag,nan},
        {"tag-large",Field::Tag,4294967296.0f}
    };
    uint failures=0;
    for(const Case& test:cases) {
        parameters[5]={64,1,0.05f,8}; samples[2].w=1;
        switch(test.field) {
        case Field::Samples: parameters[5].x=test.value; break;
        case Field::Areas: parameters[5].y=test.value; break;
        case Field::Grid: parameters[5].w=test.value; break;
        case Field::Tag: samples[2].w=test.value; break;
        }
        std::cout << test.name << " value=" << std::setprecision(10) << test.value << " call=begin\n" << std::flush;
        const uchar4 result=kfStudyPixel(parameters.data(),samples.data(),areas.data(),width,height,x,y);
        const bool pass=result.x==255 && result.y==0 && result.z==255 && result.w==0;
        std::cout << test.name << " pixel="; printPixel(result);
        std::cout << " result=" << (pass?"PASS":"FAIL") << '\n' << std::flush;
        failures+=!pass;
    }
    std::cout << "summary valid_controls=1 invalid_cases=20 failures=" << failures << '\n';
    return failures?1:0;
}
