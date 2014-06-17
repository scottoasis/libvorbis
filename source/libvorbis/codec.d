/********************************************************************
 *                                                                  *
 * THIS FILE IS PART OF THE OggVorbis SOFTWARE CODEC SOURCE CODE.   *
 * USE, DISTRIBUTION AND REPRODUCTION OF THIS LIBRARY SOURCE IS     *
 * GOVERNED BY A BSD-STYLE SOURCE LICENSE INCLUDED WITH THIS SOURCE *
 * IN 'COPYING'. PLEASE READ THESE TERMS BEFORE DISTRIBUTING.       *
 *                                                                  *
 * THE OggVorbis SOURCE CODE IS (C) COPYRIGHT 1994-2001             *
 * by the Xiph.Org Foundation http://www.xiph.org/                  *

 ********************************************************************

 function: libvorbis codec headers
 last mod: $Id: codec.h 17021 2010-03-24 09:29:41Z xiphmont $

 ********************************************************************/

module libvorbis.codec;

extern (C)
{

// ogg type definitions copied from ogg.h

	alias ogg_int64_t  = long;
	alias ogg_uint64_t = ulong;
	alias ogg_int32_t  = int;
	alias ogg_uint32_t = uint;
	alias ogg_int16_t  = short;
	alias ogg_uint16_t = ushort;
	alias ogg_int8_t   = byte;
	alias ogg_uint8_t  = ubyte;

struct oggpack_buffer {
  long endbyte;
  int  endbit;

	ubyte *buffer;
	ubyte *ptr;
  long storage;
}

struct ogg_stream_state {
	ubyte  *body_data;             /* bytes from packet bodies */
  long    body_storage;          /* storage elements allocated */
  long    body_fill;             /* elements stored; fill mark */
  long    body_returned;         /* elements of fill returned */


  int     *lacing_vals;      /* The values that will go to the segment table */
  ogg_int64_t *granule_vals; /* granulepos values for headers. Not compact
                                this way, but it is simple coupled to the
                                lacing fifo */
  long    lacing_storage;
  long    lacing_fill;
  long    lacing_packet;
  long    lacing_returned;

	ubyte   header[282];      /* working space for header encode */
  int     header_fill;

  int     e_o_s;            /* set when we have buffered the last packet in the
															 logical bitstream */
  int     b_o_s;            /* set after we've written the initial page
															 of a logical bitstream */
  long    serialno;
  long    pageno;
  ogg_int64_t  packetno;    /* sequence number for decode; the framing
															 knows where there's a hole in the data,
															 but we need coupling so that the codec
															 (which is in a separate abstraction
															 layer) also knows about the gap */
  ogg_int64_t   granulepos;

}

struct ogg_packet {
	ubyte *packet;
  long  bytes;
  long  b_o_s;
  long  e_o_s;

  ogg_int64_t  granulepos;

  ogg_int64_t  packetno;     /* sequence number for decode; the framing
                                knows where there's a hole in the data,
                                but we need coupling so that the codec
                                (which is in a separate abstraction
                                layer) also knows about the gap */
}

struct ogg_sync_state {
	ubyte *data;
  int storage;
  int fill;
  int returned;

  int unsynced;
  int headerbytes;
  int bodybytes;
}

// ogg types ends here

struct vorbis_info {
  int ver;
  int channels;
  long rate;

  /* The below bitrate declarations are *hints*.
     Combinations of the three values carry the following implications:

     all three set to the same value:
       implies a fixed rate bitstream
     only nominal set:
       implies a VBR stream that averages the nominal bitrate.  No hard
       upper/lower limit
     upper and or lower set:
       implies a VBR bitstream that obeys the bitrate limits. nominal
       may also be set to give a nominal rate.
     none set:
       the coder does not care to speculate.
  */

  long bitrate_upper;
  long bitrate_nominal;
  long bitrate_lower;
  long bitrate_window;

  void *codec_setup;
}


/* vorbis_dsp_state buffers the current vorbis audio
   analysis/synthesis state.  The DSP state belongs to a specific
   logical bitstream ****************************************************/
struct vorbis_dsp_state{
  int analysisp;
  vorbis_info *vi;

  float **pcm;
  float **pcmret;
  int      pcm_storage;
  int      pcm_current;
  int      pcm_returned;

  int  preextrapolate;
  int  eofflag;

  long lW;
  long W;
  long nW;
  long centerW;

  ogg_int64_t granulepos;
  ogg_int64_t sequence;

  ogg_int64_t glue_bits;
  ogg_int64_t time_bits;
  ogg_int64_t floor_bits;
  ogg_int64_t res_bits;

  void       *backend_state;
}

struct vorbis_block{
  /* necessary stream state for linking to the framing abstraction */
  float  **pcm;       /* this is a pointer into local storage */
  oggpack_buffer opb;

  long  lW;
  long  W;
  long  nW;
  int   pcmend;
  int   mode;

  int         eofflag;
  ogg_int64_t granulepos;
  ogg_int64_t sequence;
  vorbis_dsp_state *vd; /* For read-only access of configuration */

  /* local storage to avoid remallocing; it's up to the mapping to
     structure it */
  void               *localstore;
  long                localtop;
  long                localalloc;
  long                totaluse;
	alloc_chain *reap;

  /* bitmetrics for the frame */
  long glue_bits;
  long time_bits;
  long floor_bits;
  long res_bits;

  void *internal;

}

/* vorbis_block is a single block of data to be processed as part of
the analysis/synthesis stream; it belongs to a specific logical
bitstream, but is independent from other vorbis_blocks belonging to
that logical bitstream. *************************************************/

struct alloc_chain{
  void *ptr;
	alloc_chain *next;
};

/* vorbis_info contains all the setup information specific to the
   specific compression/decompression mode in progress (eg,
   psychoacoustic settings, channel setup, options, codebook
   etc). vorbis_info and substructures are in backends.h.
*********************************************************************/

/* the comments are not part of vorbis_info so that vorbis_info can be
   static storage */
struct vorbis_comment{
  /* unlimited user comment fields.  libvorbis writes 'libvorbis'
     whatever vendor is set to in encode */
  char **user_comments;
  int   *comment_lengths;
  int    comments;
  char  *vendor;

}


/* libvorbis encodes in two abstraction layers; first we perform DSP
   and produce a packet (see docs/analysis.txt).  The packet is then
   coded into a framed OggSquish bitstream by the second layer (see
   docs/framing.txt).  Decode is the reverse process; we sync/frame
   the bitstream and extract individual packets, then decode the
   packet back into PCM audio.

   The extra framing/packetizing is used in streaming formats, such as
   files.  Over the net (such as with UDP), the framing and
   packetization aren't necessary as they're provided by the transport
   and the streaming layer is not used */

/* Vorbis PRIMITIVES: general ***************************************/

void     vorbis_info_init(vorbis_info *vi);
void     vorbis_info_clear(vorbis_info *vi);
int      vorbis_info_blocksize(vorbis_info *vi,int zo);
void     vorbis_comment_init(vorbis_comment *vc);
void     vorbis_comment_add(vorbis_comment *vc, const char *comment);
void     vorbis_comment_add_tag(vorbis_comment *vc,
																const char *tag, const char *contents);
char    *vorbis_comment_query(vorbis_comment *vc, const char *tag, int count);
int      vorbis_comment_query_count(vorbis_comment *vc, const char *tag);
void     vorbis_comment_clear(vorbis_comment *vc);

int      vorbis_block_init(vorbis_dsp_state *v, vorbis_block *vb);
int      vorbis_block_clear(vorbis_block *vb);
void     vorbis_dsp_clear(vorbis_dsp_state *v);
double   vorbis_granule_time(vorbis_dsp_state *v,
														 ogg_int64_t granulepos);

const char *vorbis_version_string();

/* Vorbis PRIMITIVES: analysis/DSP layer ****************************/

int      vorbis_analysis_init(vorbis_dsp_state *v,vorbis_info *vi);
int      vorbis_commentheader_out(vorbis_comment *vc, ogg_packet *op);
int      vorbis_analysis_headerout(vorbis_dsp_state *v,
																	 vorbis_comment *vc,
																	 ogg_packet *op,
																	 ogg_packet *op_comm,
																	 ogg_packet *op_code);
float  **vorbis_analysis_buffer(vorbis_dsp_state *v,int vals);
int      vorbis_analysis_wrote(vorbis_dsp_state *v,int vals);
int      vorbis_analysis_blockout(vorbis_dsp_state *v,vorbis_block *vb);
int      vorbis_analysis(vorbis_block *vb,ogg_packet *op);

int      vorbis_bitrate_addblock(vorbis_block *vb);
int      vorbis_bitrate_flushpacket(vorbis_dsp_state *vd,
																		ogg_packet *op);

/* Vorbis PRIMITIVES: synthesis layer *******************************/
int      vorbis_synthesis_idheader(ogg_packet *op);
int      vorbis_synthesis_headerin(vorbis_info *vi,vorbis_comment *vc,
																	 ogg_packet *op);

int      vorbis_synthesis_init(vorbis_dsp_state *v,vorbis_info *vi);
int      vorbis_synthesis_restart(vorbis_dsp_state *v);
int      vorbis_synthesis(vorbis_block *vb,ogg_packet *op);
int      vorbis_synthesis_trackonly(vorbis_block *vb,ogg_packet *op);
int      vorbis_synthesis_blockin(vorbis_dsp_state *v,vorbis_block *vb);
int      vorbis_synthesis_pcmout(vorbis_dsp_state *v,float ***pcm);
int      vorbis_synthesis_lapout(vorbis_dsp_state *v,float ***pcm);
int      vorbis_synthesis_read(vorbis_dsp_state *v,int samples);
long     vorbis_packet_blocksize(vorbis_info *vi,ogg_packet *op);

int      vorbis_synthesis_halfrate(vorbis_info *v,int flag);
int      vorbis_synthesis_halfrate_p(vorbis_info *v);

/* Vorbis ERRORS and return codes ***********************************/

enum  OV_FALSE      = -1;
enum  OV_EOF        = -2;
enum  OV_HOLE       = -3;

enum  OV_EREAD      = -128;
enum  OV_EFAULT     = -129;
enum  OV_EIMPL      = -130;
enum  OV_EINVAL     = -131;
enum  OV_ENOTVORBIS = -132;
enum  OV_EBADHEADER = -133;
enum  OV_EVERSION   = -134;
enum  OV_ENOTAUDIO  = -135;
enum  OV_EBADPACKET = -136;
enum  OV_EBADLINK   = -137;
enum  OV_ENOSEEK    = -138;

}
