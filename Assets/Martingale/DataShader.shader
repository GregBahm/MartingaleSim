Shader "Unlit/DataShader"
{
	Properties
	{
		_StrokeThickness("Stroke Thickness", Range(0, 0.05)) = 1
	}
	SubShader
	{
		Pass
		{
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag
			#pragma target 5.0 
			
			#include "UnityCG.cginc"

			struct StrokeSegment
			{
				float height : TEXCOORD0;
				float time : TEXCOORD1;
				float unsortedIndex : TEXCOORD2;
				float sortedIndex : TEXCOORD3;
				float sessionHeight : TEXCOORD4;
				float sessionValue : TEXCOORD5;
				float End : TEXCOORD6;
			};

			struct v2g
			{
				float3 StartPosition  : TEXCOORD0;
				float3 EndPosition  : TEXCOORD1;
				float3 Color  : TEXCOORD2;
				bool End : TEXCOORD3; 
			};

			struct g2f
			{
				float4 vertex : SV_POSITION;
				float3 color : COLOR0;
			};

			float4x4 _Transform;
			float _StrokeThickness;
			float _SortStrength;

			StructuredBuffer<StrokeSegment> _TheBuffer;

			v2g vert(uint meshId : SV_VertexID, uint instanceId : SV_InstanceID)
			{
				StrokeSegment segmentStart = _TheBuffer[instanceId];
				StrokeSegment segmentEnd = _TheBuffer[instanceId - 1];

				float x = lerp(segmentStart.unsortedIndex, segmentStart.sortedIndex, _SortStrength);
				float ramp = (segmentStart.height - segmentEnd.height)  > 0;
				v2g o;
				o.StartPosition = float3(x, segmentStart.height, segmentStart.time);
				o.EndPosition = float3(x, segmentEnd.height, segmentEnd.time);
				o.End = segmentEnd.End;
				o.Color = float3(segmentStart.sessionHeight, segmentStart.sessionValue, ramp);
				if (segmentEnd.End)
				{
					o.StartPosition.yz = 0;
					o.Color = 0;
				}
				return o;
			}

			[maxvertexcount(4)]
			void geo(point v2g p[1], inout TriangleStream<g2f> triStream)
			{
				float3 strokeThickener = float3(_StrokeThickness, 0, 0);

				float3 pointA = p[0].StartPosition + strokeThickener;
				float3 pointB = p[0].EndPosition + strokeThickener;
				float3 pointC = p[0].EndPosition - strokeThickener;
				float3 pointD = p[0].StartPosition - strokeThickener;

				pointA = mul(_Transform, float4(pointA, 1)).xyz;
				pointB = mul(_Transform, float4(pointB, 1)).xyz;
				pointC = mul(_Transform, float4(pointC, 1)).xyz;
				pointD = mul(_Transform, float4(pointD, 1)).xyz;

				g2f o;
				o.color = p[0].Color;
				o.vertex = UnityObjectToClipPos(pointB);
				triStream.Append(o);

				o.vertex = UnityObjectToClipPos(pointA);
				triStream.Append(o);

				o.vertex = UnityObjectToClipPos(pointC);
				triStream.Append(o);

				o.vertex = UnityObjectToClipPos(pointD);
				triStream.Append(o);
			}
			
			fixed4 frag (g2f i) : SV_Target
			{
				return float4(i.color, 1) / 2;// *float4(0, .5, 1, 1) + 1;
			}
			ENDCG
		}
	}
}
