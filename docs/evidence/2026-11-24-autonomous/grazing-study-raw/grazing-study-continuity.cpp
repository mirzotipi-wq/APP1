#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
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


#include <iomanip>

// Independent vertical-slice Simpson integral, not production clipping.
static double reference(double cut,double slope) {
    const int count=160;const double depth=.25,width=1.0,height=.6;
    const double length=std::sqrt(1+slope*slope+cut*cut/(depth*depth));
    const double x0=std::max(-width/2,cut-slope*height/2),x1=width/2;
    if(x0>=x1)return 0;
    const double dx=(x1-x0)/count;
    auto weight=[&](int i){return i==0||i==count?1.0:i%2==0?2.0:4.0;};
    double sum=0;
    for(int i=0;i<=count;++i){
        const double x=x0+i*dx,y0=slope==0?-height/2:std::max(-height/2,(cut-x)/slope),y1=height/2;
        if(y0>=y1)continue;
        const double dy=(y1-y0)/count;double slice=0;
        for(int j=0;j<=count;++j){
            const double y=y0+j*dy,r2=x*x+y*y+depth*depth;
            slice+=weight(j)*depth*std::max(0.0,(x+slope*y-cut)/length)/(r2*r2);
        }
        sum+=weight(i)*slice*dy/3;
    }
    return sum*dx/3*1000/(width*height);
}

static float evaluate(double cut,double slope,uint grid,bool clipped=true,float intensity=1000) {
    // Match the public Swift normalized direction, then its Float32 packing.
    const double scale=std::max(1.0,std::max(std::abs(slope),std::abs(cut/.25)));
    const double a=1/scale,b=slope/scale,c=(cut/.25)/scale,length=std::sqrt(a*a+b*b+c*c);
    const float3 n(float(a/length),float(b/length),float(c/length)),p(0,0,.25f);
    const float3 right(.5f/grid,0,0),up(0,.3f/grid,0);
    const float nx=dot(n,right),ny=dot(n,up),span=std::abs(nx)+std::abs(ny);
    const float4 axis={0,0,1,1};float total=0;
    auto sample=[&](float3 position,float weight){
        const auto incident=kfStudyIncident(position,intensity/float(grid*grid)*weight,axis,p,n);
        if(!incident.valid)throw std::runtime_error("unexpected near-field rejection");
        total+=incident.lux;
    };
    for(uint row=0;row<grid;++row)for(uint col=0;col<grid;++col){
        // Same Double prepared midpoints converted to Float as compute input.
        const float3 center(float((double(col)+.5)/grid-.5),float(((double(row)+.5)/grid-.5)*.6),0);
        const float incidence=dot(n,center-p);
        if(clipped&&incidence<=-span)continue;
        if(!clipped||incidence>=span){sample(center,1);continue;}
        const float3 zero(0,0,0);float3 polygon[5]={zero,zero,zero,zero,zero};
        const uint count=kfClipStudyCell(incidence,nx,ny,polygon);
        for(uint j=1;j+1<count;++j){
            const auto a=polygon[0],b=polygon[j],c=polygon[j+1],ab=b-a,ac=c-a;
            const float weight=std::abs(ab.x*ac.y-ab.y*ac.x)/24;
            const float3 points[3]={(a*4+b+c)/6,(b*4+a+c)/6,(c*4+a+b)/6};
            for(const auto& q:points)sample(center+right*q.x+up*q.y,weight);
        }
    }
    return total;
}


int main(){
    std::cout<<std::setprecision(17);
    for(bool clipped:{false,true}){
        double values[3];uint i=0;
        for(double cut:{.6-1e-8,.6,.6+1e-8}){
            values[i++]=evaluate(cut,1,8,clipped);
            std::cout<<"FLOAT32 clipped="<<clipped<<" cut="<<cut<<" visible_lux="<<values[i-1]<<" simpson_lux="<<reference(cut,1)<<"\n";
        }
        std::cout<<"FLOAT32 clipped="<<clipped<<" span_lux="<<std::abs(values[2]-values[0])<<" relative_span="<<std::abs(values[2]-values[0])/values[1]<<"\n";
    }
}
