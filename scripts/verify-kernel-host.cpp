#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <iostream>
#include <stdexcept>
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
#include "../App/StudyKernel.h"

static uint32_t readU32(std::istream& s) {
    unsigned char b[4];
    if (!s.read(reinterpret_cast<char*>(b),4)) throw std::runtime_error("short input");
    return uint32_t(b[0]) | uint32_t(b[1])<<8 | uint32_t(b[2])<<16 | uint32_t(b[3])<<24;
}
static float readF32(std::istream& s) {
    const uint32_t bits=readU32(s);float value;std::memcpy(&value,&bits,4);
    if(!isfinite(value))throw std::runtime_error("nonfinite input");
    return value;
}
static std::vector<float4> rows(std::istream& s,uint32_t n) {
    std::vector<float4> v;v.reserve(n);
    for(uint32_t i=0;i<n;++i){float4 r; r.x=readF32(s);r.y=readF32(s);r.z=readF32(s);r.w=readF32(s);v.push_back(r);}
    return v;
}
static bool compare(const char* file) {
    std::ifstream s(file,std::ios::binary);
    const uint w=readU32(s),h=readU32(s),np=readU32(s),ns=readU32(s),na=readU32(s),expectedInvalid=readU32(s);
    if(w<24||w>192||w%3||h!=w*2/3||np!=6||ns>12*64*3||na>36||ns%3||na%3)
        throw std::runtime_error("invalid fixture header");
    const auto p=rows(s,np),samples=rows(s,ns),areas=rows(s,na);
    if(p[5].x!=float(ns/3)||p[5].y!=float(na/3))throw std::runtime_error("invalid sample counts");
    std::vector<uint8_t> ref(w*h*4);
    if(!s.read(reinterpret_cast<char*>(ref.data()),ref.size())||s.peek()!=std::char_traits<char>::eof())
        throw std::runtime_error("invalid reference length");
    uint64_t total=0,outliers=0;uint invalid=0,maximum=0;
    for(uint y=0;y<h;++y)for(uint x=0;x<w;++x){
        const uchar4 c=kfStudyPixel(p.data(),samples.data(),areas.data(),w,h,x,y);
        if(c.w==0){if(c.x!=255||c.y!=0||c.z!=255)throw std::runtime_error("bad invalid flag");++invalid;}
        else if(c.w!=255)throw std::runtime_error("bad alpha");
        const uint8_t rgb[]={c.x,c.y,c.z}; const uint offset=4*(y*w+x);
        for(uint i=0;i<3;++i){const uint e=uint(abs(int(rgb[i])-int(ref[offset+i])));total+=e;maximum=max(maximum,e);outliers+=e>4;}
    }
    const double count=double(w)*h*3,mean=total/count,fraction=outliers/count;
    const bool pass=invalid==expectedInvalid&&mean<=1.0&&fraction<=0.005;
    std::cout<<file<<": mean="<<mean<<", max="<<maximum<<", >4 fraction="<<fraction
             <<", invalid="<<invalid<<"/"<<expectedInvalid<<", "<<(pass?"PASS":"FAIL")<<"\n";
    return pass;
}
int main(int argc,char** argv) {
    if(argc<2)return 2;
    try{bool pass=true;for(int i=1;i<argc;++i)pass=compare(argv[i])&&pass;return pass?0:1;}
    catch(const std::exception& e){std::cerr<<e.what()<<"\n";return 2;}
}
