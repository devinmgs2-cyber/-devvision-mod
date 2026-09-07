        sampler2D _MainTex;
        float4 _MainTex_TexelSize;
        float _Shift;
        float _Intensity;

        struct appdata_t {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2f {
            float2 uv : TEXCOORD0;
            float4 vertex : SV_POSITION;
        };

        v2f vert (appdata_t v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv;
            return o;
        }

        fixed4 frag (v2f i) : SV_Target
        {
            float2 uv = i.uv;

            float2 offset = float2(_Shift, 0.0) * _MainTex_TexelSize.y * 512.0;

            fixed4 r = tex2D(_MainTex, uv + offset);
            fixed4 g = tex2D(_MainTex, uv);
            fixed4 b = tex2D(_MainTex, uv - offset);

            fixed4 rgb = fixed4(r.r, g.g, b.b, 1.0);
            fixed4 orig = tex2D(_MainTex, uv);

            fixed4 outCol = lerp(orig, rgb, saturate(_Intensity));
            return outCol;
        }
        ENDCG
    }
}
Fallback Off