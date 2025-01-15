using System;
using System.Collections.Generic;

namespace SonicRetro.SonLVL.API.S3K
{
	public class Layout : LayoutFormatSeparate
	{	
		// Internal Read Generic Layout
		private void ReadLayoutInternal(byte[] rawdata, ref ushort[,] layout)
		{
			int width = rawdata[0] + 1;
			int height = rawdata[1] + 1;
			layout = new ushort[width, height];
			
			for (int row = 0; row < height; row++)
			{
				ushort ptr = ByteConverter.ToUInt16(rawdata, 2 + (row * 2));
				if (ptr != 0)
					for (int col = 0; col < width; col++)
						layout[col, row] = rawdata[ptr + col];
			}
		}

		// Read Foreground Override
		public override void ReadFG(byte[] rawdata, LayoutData layout)
		{
			ReadLayoutInternal(rawdata, ref layout.FGLayout);
		}

		// Read Foreground Override
		public override void ReadBG(byte[] rawdata, LayoutData layout)
		{
			ReadLayoutInternal(rawdata, ref layout.BGLayout);
		}

		// Internal Write Generic Layout
		private void WriteLayoutInternal(ushort[,] layout, out byte[] rawdata)
		{
			List<byte> tmp = new List<byte>();
			
			int width = layout.GetLength(0);
			int height = layout.GetLength(1);
			tmp.Add((byte)(width - 1));
			tmp.Add((byte)(height - 1));
			
			// Layout Pointers
			for (int row = 0; row < height; row++)
			{
				tmp.AddRange(ByteConverter.GetBytes((ushort)(2 + (height * 2) + (row * width))));
			}

			// Layout Data
			for (int row = 0; row < height; row++)
				for (int col = 0; col < width; col++)
					tmp.Add((byte)layout[col, row]);

			rawdata = tmp.ToArray();
		}

		// Write Foreground Override
		public override void WriteFG(LayoutData layout, out byte[] rawdata)
		{
			WriteLayoutInternal(layout.FGLayout, out rawdata);
		}

		// Write Background Override
		public override void WriteBG(LayoutData layout, out byte[] rawdata)
		{
			WriteLayoutInternal(layout.BGLayout, out rawdata);
		}

		public override bool IsResizable { get { return true; } }

		public override System.Drawing.Size MaxSize { get { return new System.Drawing.Size(256, 256); } }

		public override System.Drawing.Size DefaultSize { get { return new System.Drawing.Size(128, 16); } }

		public override int MaxBytes { get { return 32768; } }
    }
}
